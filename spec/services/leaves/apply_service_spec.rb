require "rails_helper"

RSpec.describe Leaves::ApplyService do
  let(:company)       { create(:company) }
  let(:leave_policy)  { create(:leave_policy, company: company) }
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
  end
end
