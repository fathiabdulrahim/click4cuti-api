require "rails_helper"

RSpec.describe Leaves::ApprovalService do
  let(:company)      { create(:company) }
  let(:leave_policy) { create(:leave_policy, company: company) }
  let(:leave_type)   { create(:leave_type, leave_policy: leave_policy) }
  let(:user)         { create(:user, :employee, company: company) }
  let(:approver)     { create(:user, :manager, company: company) }

  let!(:leave_balance) do
    create(:leave_balance,
           user:           user,
           leave_type:     leave_type,
           year:           Date.current.year,
           total_entitled: 12.0,
           remaining_days: 10.0,
           used_days:      0.0,
           pending_days:   2.0)
  end

  let(:leave_application) do
    create(:leave_application,
           user:       user,
           leave_type: leave_type,
           start_date: Date.new(Date.current.year, 4, 13),
           end_date:   Date.new(Date.current.year, 4, 14),
           total_days: 2.0,
           status:     "PENDING")
  end

  before do
    allow(LeaveNotificationJob).to receive(:perform_later)
  end

  describe "#call" do
    context "when approving" do
      let(:params) { { status: "APPROVED", reviewer_remarks: "Enjoy your leave" } }

      subject { described_class.new(leave_application, approver, params).call }

      it "changes status to approved" do
        result = subject
        expect(result.status).to eq("approved")
      end

      it "sets approved_by to approver id" do
        result = subject
        expect(result.approved_by).to eq(approver.id)
      end

      it "sets reviewer_remarks" do
        result = subject
        expect(result.reviewer_remarks).to eq("Enjoy your leave")
      end

      it "moves balance from pending to used" do
        subject
        leave_balance.reload

        expect(leave_balance.pending_days).to eq(0.0)
        expect(leave_balance.used_days).to eq(2.0)
        expect(leave_balance.remaining_days).to eq(10.0)
      end

      it "enqueues a notification" do
        subject
        expect(LeaveNotificationJob).to have_received(:perform_later)
          .with(leave_application.id, "approved")
      end
    end

    context "when rejecting" do
      let(:params) { { status: "REJECTED", reviewer_remarks: "Staffing issues" } }

      subject { described_class.new(leave_application, approver, params).call }

      it "changes status to rejected" do
        result = subject
        expect(result.status).to eq("rejected")
      end

      it "releases pending balance without incrementing used" do
        subject
        leave_balance.reload

        expect(leave_balance.pending_days).to eq(0.0)
        expect(leave_balance.used_days).to eq(0.0)
        expect(leave_balance.remaining_days).to eq(12.0)
      end
    end

    context "when application is already approved" do
      let(:leave_application) do
        create(:leave_application, :approved,
               user: user, leave_type: leave_type,
               start_date: Date.new(Date.current.year, 4, 13),
               end_date:   Date.new(Date.current.year, 4, 14),
               total_days: 2.0)
      end
      let(:params) { { status: "REJECTED", reviewer_remarks: "Changed mind" } }

      it "raises an error" do
        expect {
          described_class.new(leave_application, approver, params).call
        }.to raise_error(Leaves::ApprovalService::Error, "Application is not pending")
      end
    end

    context "when application is already rejected" do
      let(:leave_application) do
        create(:leave_application, :rejected,
               user: user, leave_type: leave_type,
               start_date: Date.new(Date.current.year, 4, 13),
               end_date:   Date.new(Date.current.year, 4, 14),
               total_days: 2.0)
      end
      let(:params) { { status: "APPROVED", reviewer_remarks: "Override" } }

      it "raises an error" do
        expect {
          described_class.new(leave_application, approver, params).call
        }.to raise_error(Leaves::ApprovalService::Error, "Application is not pending")
      end
    end
  end
end
