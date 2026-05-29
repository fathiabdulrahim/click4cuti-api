require "rails_helper"

RSpec.describe Leaves::ApplyService do
  let(:company)       { create(:company) }
  let(:leave_policy)  { create(:leave_policy, company: company, advance_notice_days: 0) }
  let(:leave_type) do
    create(:leave_type,
           leave_policy:       leave_policy,
           max_consecutive_days: 3,
           is_active:          true)
  end
  let(:user)          { create(:user, :employee, company: company) }
  let!(:user_leave_policy) do
    create(:user_leave_policy, user: user, leave_policy: leave_policy)
  end
  let!(:leave_balance) do
    create(:leave_balance,
           user:           user,
           leave_type:     leave_type,
           year:           Date.current.year,
           total_entitled: 12.0,
           remaining_days: 12.0,
           used_days:      0.0,
           pending_days:   0.0)
  end
  let(:work_schedule) do
    create(:work_schedule, company: company, rest_days: "Saturday,Sunday")
  end
  let!(:user_work_schedule) do
    create(:user_work_schedule, user: user, work_schedule: work_schedule)
  end

  let(:params) do
    {
      leave_type_id: leave_type.id,
      start_date:    "2026-04-13",
      end_date:      "2026-04-14",
      reason:        "Personal matters"
    }
  end

  subject { described_class.new(user, params).call }

  before do
    allow(LeaveNotificationJob).to receive(:perform_later)
    allow(WarningLetterJob).to receive(:perform_later)
  end

  describe "#call" do
    context "happy path" do
      it "creates a leave application with correct total_days" do
        application = subject

        expect(application).to be_persisted
        expect(application.status).to eq("pending")
        expect(application.total_days).to eq(2.0)
        expect(application.user).to eq(user)
        expect(application.leave_type).to eq(leave_type)
        expect(application.reason).to eq("Personal matters")
      end

      it "updates pending_days in leave balance" do
        subject

        leave_balance.reload
        expect(leave_balance.pending_days).to eq(2.0)
        expect(leave_balance.remaining_days).to eq(10.0)
      end

      it "enqueues a leave notification job" do
        application = subject

        expect(LeaveNotificationJob).to have_received(:perform_later)
          .with(application.id, "applied")
      end
    end

    context "when leave type is inactive" do
      before { leave_type.update!(is_active: false) }

      it "raises an error" do
        expect { subject }.to raise_error(
          Leaves::ApplyService::Error, "Leave type is not available"
        )
      end
    end

    context "when balance is insufficient" do
      before { leave_balance.update!(remaining_days: 0.0, used_days: 12.0) }

      it "raises an error" do
        expect { subject }.to raise_error(
          Leaves::ApplyService::Error, /Insufficient leave balance/
        )
      end
    end

    context "when max_times_per_year is reached" do
      let(:leave_type) do
        create(:leave_type, :emergency_leave,
               leave_policy: leave_policy,
               max_times_per_year: 3,
               is_active: true)
      end

      before do
        3.times do |i|
          create(:leave_application, :approved,
                 user:       user,
                 leave_type: leave_type,
                 start_date: Date.new(Date.current.year, 1, 5 + i),
                 end_date:   Date.new(Date.current.year, 1, 5 + i),
                 total_days: 1.0)
        end
      end

      it "raises an error about exceeding the yearly limit" do
        expect { subject }.to raise_error(
          Leaves::ApplyService::Error, /maximum.*limit for this year/
        )
      end
    end

    context "when the requested range contains no working days" do
      let(:params) do
        {
          leave_type_id: leave_type.id,
          # 2026-04-11 is Saturday, 2026-04-12 is Sunday — both rest days for the user
          start_date:    "2026-04-11",
          end_date:      "2026-04-12",
          reason:        "Weekend trip"
        }
      end

      it "raises an error" do
        expect { subject }.to raise_error(
          Leaves::ApplyService::Error, "Selected dates contain no working days"
        )
      end

      it "does not create the application or touch balance" do
        expect {
          begin; subject; rescue Leaves::ApplyService::Error; end
        }.not_to change(LeaveApplication, :count)
        expect(leave_balance.reload.pending_days).to eq(0.0)
      end
    end

    context "when total days exceed max_consecutive_days" do
      let(:params) do
        {
          leave_type_id: leave_type.id,
          start_date:    "2026-04-13",
          end_date:      "2026-04-17",
          reason:        "Extended holiday",
          extended_reason: "Family event overseas"
        }
      end

      it "sets requires_ceo_approval to true" do
        application = subject

        expect(application.requires_ceo_approval).to be true
        expect(application.total_days).to eq(5.0)
      end
    end

    context "when leave type uses shared balance (e.g. Emergency → Annual)" do
      let(:annual_type) do
        create(:leave_type, leave_policy: leave_policy, max_consecutive_days: 3)
      end
      let(:leave_type) do
        create(:leave_type, :emergency_leave,
               leave_policy:    leave_policy,
               shared_balance:  annual_type,
               is_active:       true)
      end
      let!(:annual_balance) do
        create(:leave_balance,
               user:           user,
               leave_type:     annual_type,
               year:           Date.current.year,
               total_entitled: 12.0,
               remaining_days: 12.0,
               used_days:      0.0,
               pending_days:   0.0)
      end
      let!(:leave_balance) { nil }

      it "increments pending_days on the shared (annual) balance" do
        subject

        annual_balance.reload
        expect(annual_balance.pending_days).to eq(2.0)
        expect(annual_balance.remaining_days).to eq(10.0)
      end

      it "does not create a balance for the dependent (emergency) leave type" do
        subject

        expect(LeaveBalance.find_by(user: user, leave_type: leave_type)).to be_nil
      end

      context "when shared balance is exhausted" do
        before { annual_balance.update!(remaining_days: 0.0, used_days: 12.0) }

        it "raises Insufficient leave balance referencing the emergency type" do
          expect { subject }.to raise_error(
            Leaves::ApplyService::Error, /Insufficient leave balance for Emergency Leave/
          )
        end
      end
    end

    context "WarningChecker integration" do
      let(:leave_type) do
        create(:leave_type, :emergency_leave,
               leave_policy:       leave_policy,
               max_times_per_year: 99,
               is_active:          true)
      end

      it "invokes WarningChecker with the user and leave type" do
        checker = instance_double(Leaves::WarningChecker, check!: nil)
        expect(Leaves::WarningChecker).to receive(:new).with(user, leave_type).and_return(checker)

        subject
      end

      context "when emergency leave count exceeds the threshold" do
        before do
          Leaves::WarningChecker::EMERGENCY_LEAVE_THRESHOLD.times do |i|
            create(:leave_application, :approved,
                   user:       user,
                   leave_type: leave_type,
                   start_date: Date.new(Date.current.year, 1, 5 + i),
                   end_date:   Date.new(Date.current.year, 1, 5 + i),
                   total_days: 1.0)
          end
        end

        it "creates a warning letter and enqueues the job" do
          expect { subject }.to change(WarningLetter, :count).by(1)
          expect(WarningLetterJob).to have_received(:perform_later)
            .with(user.id, leave_type.id, Date.current.year)
        end
      end
    end

    context "when persisting day details fails" do
      let(:params) do
        {
          leave_type_id: leave_type.id,
          start_date:    "2026-04-13",
          end_date:      "2026-04-14",
          reason:        "Errands",
          leave_day_details_attributes: [
            { leave_date: "2026-04-13", day_type: "FULL_DAY" },
            { leave_date: "2026-04-14", day_type: "INVALID_TYPE" }
          ]
        }
      end

      it "rolls back the application and the balance increment" do
        expect {
          begin; subject; rescue StandardError; end
        }.not_to change(LeaveApplication, :count)

        expect(leave_balance.reload.pending_days).to eq(0.0)
      end
    end

    context "with leave_day_details_attributes" do
      let(:params) do
        {
          leave_type_id: leave_type.id,
          start_date:    "2026-04-13",
          end_date:      "2026-04-14",
          reason:        "Errands",
          leave_day_details_attributes: [
            { leave_date: "2026-04-13", day_type: "FULL_DAY" },
            { leave_date: "2026-04-14", day_type: "HALF_DAY_AM" }
          ]
        }
      end

      it "creates leave day details records" do
        application = subject

        expect(application.leave_day_details.count).to eq(2)
        expect(application.total_days).to eq(1.5)
      end

      it "updates pending_days based on day detail values" do
        subject

        leave_balance.reload
        expect(leave_balance.pending_days).to eq(1.5)
      end
    end

    context "document upload" do
      let(:leave_type) do
        create(:leave_type, :sick_leave, leave_policy: leave_policy, is_active: true)
      end

      context "when the leave type requires a document but none is provided" do
        it "raises an error and persists nothing" do
          expect { subject }.to raise_error(
            Leaves::ApplyService::Error, /supporting document is required/
          )
          expect(LeaveApplication.count).to eq(0)
        end
      end

      context "when a valid document is provided" do
        let(:document) do
          Rack::Test::UploadedFile.new(
            StringIO.new("%PDF-1.4 test"), "application/pdf", original_filename: "mc.pdf"
          )
        end
        let(:params) do
          {
            leave_type_id: leave_type.id,
            start_date:    "2026-04-13",
            end_date:      "2026-04-14",
            reason:        "Medical leave",
            document:      document
          }
        end

        it "attaches a leave document with metadata" do
          application = subject

          expect(application.leave_documents.count).to eq(1)
          doc = application.leave_documents.first
          expect(doc.file_name).to eq("mc.pdf")
          expect(doc.content_type).to eq("application/pdf")
          expect(doc.file).to be_attached
        end
      end

      context "when the document is an unsupported type" do
        let(:document) do
          Rack::Test::UploadedFile.new(
            StringIO.new("MZ"), "application/x-msdownload", original_filename: "virus.exe"
          )
        end
        let(:params) do
          {
            leave_type_id: leave_type.id,
            start_date:    "2026-04-13",
            end_date:      "2026-04-14",
            reason:        "Medical leave",
            document:      document
          }
        end

        it "rolls back the whole application" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
          expect(LeaveApplication.count).to eq(0)
        end
      end
    end

    context "advance notice validation" do
      let(:notice_policy) { create(:leave_policy, company: company, advance_notice_days: 7) }
      let(:leave_type) do
        create(:leave_type, leave_policy: notice_policy, max_consecutive_days: nil, is_active: true)
      end

      context "when the start date is inside the notice window" do
        let(:params) do
          {
            leave_type_id: leave_type.id,
            start_date:    (Date.current + 2).to_s,
            end_date:      (Date.current + 3).to_s,
            reason:        "Too soon to apply"
          }
        end

        it "raises an advance notice error and persists nothing" do
          expect { subject }.to raise_error(
            Leaves::ApplyService::Error, /at least 7 day\(s\) in advance/
          )
          expect(LeaveApplication.count).to eq(0)
        end
      end

      context "when the start date satisfies the notice requirement" do
        let(:params) do
          {
            leave_type_id: leave_type.id,
            start_date:    (Date.current + 7).to_s,
            end_date:      (Date.current + 13).to_s,
            reason:        "Planned well ahead"
          }
        end

        it "creates the application" do
          expect(subject).to be_persisted
        end
      end

      context "when the policy has zero advance notice" do
        let(:notice_policy) { create(:leave_policy, company: company, advance_notice_days: 0) }
        let(:params) do
          {
            leave_type_id: leave_type.id,
            start_date:    Date.current.to_s,
            end_date:      (Date.current + 4).to_s,
            reason:        "Same-day leave allowed"
          }
        end

        it "allows an application starting today" do
          expect(subject).to be_persisted
        end
      end
    end
  end
end
