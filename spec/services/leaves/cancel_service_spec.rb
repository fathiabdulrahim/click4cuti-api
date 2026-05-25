require "rails_helper"

RSpec.describe Leaves::CancelService do
  let(:company)      { create(:company) }
  let(:leave_policy) { create(:leave_policy, company: company) }
  let(:leave_type)   { create(:leave_type, leave_policy: leave_policy) }
  let(:user)         { create(:user, :employee, company: company) }

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

  describe "#call" do
    context "when cancelling a PENDING application" do
      let(:leave_application) do
        create(:leave_application,
               user:       user,
               leave_type: leave_type,
               start_date: Date.new(Date.current.year, 4, 13),
               end_date:   Date.new(Date.current.year, 4, 14),
               total_days: 2.0,
               status:     "PENDING")
      end

      subject { described_class.new(leave_application, user).call }

      it "changes status to cancelled" do
        result = subject
        expect(result.status).to eq("cancelled")
      end

      it "releases pending_days without touching used_days" do
        subject
        leave_balance.reload

        expect(leave_balance.pending_days).to eq(0.0)
        expect(leave_balance.used_days).to eq(0.0)
        expect(leave_balance.remaining_days).to eq(12.0)
      end

      it "returns the application" do
        expect(subject).to eq(leave_application)
      end
    end

    context "when cancelling an APPROVED application" do
      let(:leave_balance) do
        create(:leave_balance,
               user:           user,
               leave_type:     leave_type,
               year:           Date.current.year,
               total_entitled: 12.0,
               remaining_days: 10.0,
               used_days:      2.0,
               pending_days:   0.0)
      end

      let(:leave_application) do
        create(:leave_application,
               user:       user,
               leave_type: leave_type,
               start_date: Date.new(Date.current.year, 4, 13),
               end_date:   Date.new(Date.current.year, 4, 14),
               total_days: 2.0,
               status:     "APPROVED")
      end

      subject { described_class.new(leave_application, user).call }

      it "changes status to cancelled" do
        result = subject
        expect(result.status).to eq("cancelled")
      end

      it "releases used_days back to remaining" do
        subject
        leave_balance.reload

        expect(leave_balance.used_days).to eq(0.0)
        expect(leave_balance.pending_days).to eq(0.0)
        expect(leave_balance.remaining_days).to eq(12.0)
      end
    end

    context "when application is already REJECTED" do
      let(:leave_application) do
        create(:leave_application, :rejected,
               user:       user,
               leave_type: leave_type,
               start_date: Date.new(Date.current.year, 4, 13),
               end_date:   Date.new(Date.current.year, 4, 14),
               total_days: 2.0)
      end

      it "raises an error" do
        expect {
          described_class.new(leave_application, user).call
        }.to raise_error(Leaves::CancelService::Error, "Only pending or approved applications can be cancelled")
      end
    end

    context "when application is already CANCELLED" do
      let(:leave_application) do
        create(:leave_application, :cancelled,
               user:       user,
               leave_type: leave_type,
               start_date: Date.new(Date.current.year, 4, 13),
               end_date:   Date.new(Date.current.year, 4, 14),
               total_days: 2.0)
      end

      it "raises an error" do
        expect {
          described_class.new(leave_application, user).call
        }.to raise_error(Leaves::CancelService::Error, "Only pending or approved applications can be cancelled")
      end
    end

    context "when leave type uses shared balance (e.g. Emergency → Annual)" do
      let(:annual_type) { create(:leave_type, leave_policy: leave_policy) }
      let(:emergency_type) do
        create(:leave_type, leave_policy: leave_policy,
               shared_balance: annual_type)
      end

      let!(:annual_balance) do
        create(:leave_balance,
               user:           user,
               leave_type:     annual_type,
               year:           Date.current.year,
               total_entitled: 12.0,
               remaining_days: 8.0,
               used_days:      2.0,
               pending_days:   2.0)
      end

      let(:leave_application) do
        create(:leave_application,
               user:       user,
               leave_type: emergency_type,
               start_date: Date.new(Date.current.year, 4, 13),
               end_date:   Date.new(Date.current.year, 4, 14),
               total_days: 2.0,
               status:     "PENDING")
      end

      subject { described_class.new(leave_application, user).call }

      it "releases pending_days from the shared balance (not the leave type's own)" do
        subject
        annual_balance.reload

        expect(annual_balance.pending_days).to eq(0.0)
        expect(annual_balance.remaining_days).to eq(10.0)
      end
    end
  end
end
