require "rails_helper"

RSpec.describe Dashboard::AdminStatsService do
  let(:company)       { create(:company) }
  let(:other_company) { create(:company) }
  let(:leave_policy)  { create(:leave_policy, company: company) }
  let(:leave_type)    { create(:leave_type, leave_policy: leave_policy) }

  let!(:employee1) { create(:user, :employee, company: company, is_active: true) }
  let!(:employee2) { create(:user, :employee, company: company, is_active: true) }
  let!(:other_employee) { create(:user, :employee, company: other_company, is_active: true) }

  let(:today) { Date.current }

  # Company leave applications
  let!(:pending_app) do
    create(:leave_application,
           user: employee1, leave_type: leave_type,
           status: "PENDING",
           start_date: today + 7, end_date: today + 8,
           total_days: 2.0)
  end

  let!(:approved_today) do
    create(:leave_application, :approved,
           user: employee2, leave_type: leave_type,
           start_date: today, end_date: today + 1,
           total_days: 2.0)
  end

  let!(:approved_ytd_app) do
    create(:leave_application, :approved,
           user: employee1, leave_type: leave_type,
           start_date: Date.new(today.year, 2, 10),
           end_date:   Date.new(today.year, 2, 11),
           total_days: 2.0)
  end

  let!(:rejected_app) do
    create(:leave_application, :rejected,
           user: employee1, leave_type: leave_type,
           start_date: Date.new(today.year, 3, 5),
           end_date:   Date.new(today.year, 3, 5),
           total_days: 1.0)
  end

  # Other company leave application (should not appear for company admin)
  let(:other_leave_type) { create(:leave_type, leave_policy: create(:leave_policy, company: other_company)) }
  let!(:other_app) do
    create(:leave_application,
           user: other_employee, leave_type: other_leave_type,
           status: "PENDING",
           start_date: today + 3, end_date: today + 4,
           total_days: 2.0)
  end

  describe "#call" do
    context "company admin" do
      let(:admin_user) { create(:admin_user, :company, company: company) }

      subject { described_class.new(admin_user).call }

      it "returns the expected keys" do
        result = subject

        expect(result).to include(
          :total_employees,
          :pending_approvals,
          :on_leave_today,
          :approved_ytd,
          :rejected_ytd,
          :leave_by_type,
          :recent_applications
        )
      end

      it "counts only own company employees" do
        expect(subject[:total_employees]).to eq(2)
      end

      it "counts pending approvals for own company" do
        expect(subject[:pending_approvals]).to eq(1)
      end

      it "counts employees on leave today" do
        expect(subject[:on_leave_today]).to eq(1)
      end

      it "counts approved applications year-to-date" do
        # approved_today + approved_ytd_app = 2
        expect(subject[:approved_ytd]).to eq(2)
      end

      it "counts rejected applications year-to-date" do
        expect(subject[:rejected_ytd]).to eq(1)
      end

      it "returns leave breakdown by type" do
        result = subject[:leave_by_type]
        expect(result).to be_a(Hash)
        expect(result.values.sum).to eq(2) # 2 approved applications
      end

      it "returns recent applications as an array" do
        result = subject[:recent_applications]
        expect(result).to be_an(Array)
        expect(result.length).to be <= 10

        first = result.first
        expect(first).to include(:id, :user, :leave_type, :status, :start_date, :total_days)
      end

      it "does not include other company data" do
        result = subject
        user_names = result[:recent_applications].map { |a| a[:user] }
        expect(user_names).not_to include(other_employee.full_name)
      end
    end

    context "super_admin" do
      let(:admin_user) { create(:admin_user, :super_admin) }

      subject { described_class.new(admin_user).call }

      it "sees all employees across companies" do
        expect(subject[:total_employees]).to eq(3)
      end

      it "sees all pending approvals across companies" do
        expect(subject[:pending_approvals]).to eq(2)
      end
    end
  end
end
