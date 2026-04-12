require "rails_helper"

RSpec.describe Users::OnboardService do
  let(:company)      { create(:company) }
  let(:leave_policy) { create(:leave_policy, company: company, is_active: true) }
  let!(:annual_leave) do
    create(:leave_type,
           leave_policy:       leave_policy,
           name:               "Annual Leave",
           default_days_tier1: 8,
           is_active:          true)
  end
  let!(:sick_leave) do
    create(:leave_type, :sick_leave,
           leave_policy: leave_policy,
           is_active:    true)
  end
  let!(:emergency_leave) do
    create(:leave_type, :emergency_leave,
           leave_policy:       leave_policy,
           shared_balance_with: annual_leave.id,
           is_active:          true)
  end
  let(:department)  { create(:department, company: company) }
  let(:designation) { create(:designation, company: company) }

  let(:admin_user) { create(:admin_user, :company, company: company) }

  let(:params) do
    {
      full_name:      "Ali bin Ahmad",
      email:          "ali@example.com",
      phone:          "0123456789",
      role:           "EMPLOYEE",
      join_date:      Date.current,
      gender:         "MALE",
      department_id:  department.id,
      designation_id: designation.id
    }
  end

  subject { described_class.new(params, admin_user).call }

  describe "#call" do
    it "creates a user with correct attributes" do
      user = subject

      expect(user).to be_persisted
      expect(user.full_name).to eq("Ali bin Ahmad")
      expect(user.email).to eq("ali@example.com")
      expect(user.company_id).to eq(company.id)
      expect(user.role).to eq("employee")
    end

    it "assigns the user to the active leave policy" do
      user = subject

      expect(user.user_leave_policies.count).to eq(1)

      ulp = user.user_leave_policies.first
      expect(ulp.leave_policy).to eq(leave_policy)
      expect(ulp.effective_from).to eq(user.join_date)
    end

    it "initializes leave balances for non-shared leave types" do
      user = subject

      balances = LeaveBalance.where(user: user, year: Date.current.year)
      balance_type_ids = balances.pluck(:leave_type_id)

      # Annual Leave and Sick Leave get balances; Emergency Leave shares Annual balance
      expect(balance_type_ids).to include(annual_leave.id)
      expect(balance_type_ids).to include(sick_leave.id)
      expect(balance_type_ids).not_to include(emergency_leave.id)
    end

    it "resolves company_id from admin_user when scope is company" do
      user = subject
      expect(user.company_id).to eq(admin_user.company_id)
    end

    context "when admin_user is super_admin with explicit company_id" do
      let(:admin_user) { create(:admin_user, :super_admin) }
      let(:params_with_company) { params.merge(company_id: company.id) }

      it "uses the provided company_id" do
        user = described_class.new(params_with_company, admin_user).call
        expect(user.company_id).to eq(company.id)
      end
    end

    context "when company_id is missing for super_admin" do
      let(:admin_user) { create(:admin_user, :super_admin) }

      it "raises an error" do
        expect {
          described_class.new(params, admin_user).call
        }.to raise_error(Users::OnboardService::Error, "company_id is required")
      end
    end
  end
end
