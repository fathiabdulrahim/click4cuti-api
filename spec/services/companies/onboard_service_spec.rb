require "rails_helper"

RSpec.describe Companies::OnboardService do
  let(:company) { build(:company) }

  subject { described_class.new(company).call }

  describe "#call" do
    it "persists the company" do
      result = subject
      expect(result).to be_persisted
    end

    it "creates default departments" do
      subject

      department_names = company.departments.pluck(:name)
      expect(department_names).to include(
        "Human Resources", "Finance", "Operations",
        "Technology", "Sales", "Marketing"
      )
      expect(company.departments.count).to eq(6)
    end

    it "creates default designations" do
      subject

      titles = company.designations.pluck(:title)
      expect(titles).to include("Manager", "Executive", "Executive Director", "Staff")
      expect(company.designations.count).to eq(4)
    end

    it "creates a leave policy with name 'Standard Leave Policy'" do
      subject

      policy = company.leave_policies.first
      expect(policy).to be_present
      expect(policy.name).to eq("Standard Leave Policy")
    end

    it "creates five leave types under the policy" do
      subject

      policy = company.leave_policies.first
      leave_type_names = policy.leave_types.pluck(:name)

      expect(leave_type_names).to include(
        "Annual Leave", "Sick Leave", "Emergency Leave",
        "Maternity Leave", "Paternity Leave"
      )
      expect(policy.leave_types.count).to eq(5)
    end

    it "creates Annual Leave with EA 1955 tier entitlements" do
      subject

      annual = company.leave_policies.first.leave_types.find_by(name: "Annual Leave")
      expect(annual.default_days_tier1).to eq(8)
      expect(annual.default_days_tier2).to eq(12)
      expect(annual.default_days_tier3).to eq(16)
    end

    it "creates Emergency Leave with shared_balance_with pointing to Annual Leave" do
      subject

      policy   = company.leave_policies.first
      annual   = policy.leave_types.find_by(name: "Annual Leave")
      emergency = policy.leave_types.find_by(name: "Emergency Leave")

      expect(emergency.shared_balance_with).to eq(annual.id)
    end

    it "creates a default work schedule" do
      subject

      schedule = company.work_schedules.first
      expect(schedule).to be_present
      expect(schedule.name).to eq("Standard Office Hours")
      expect(schedule.rest_days).to eq("Saturday,Sunday")
    end

    it "seeds mandatory public holidays" do
      subject

      holidays = company.public_holidays
      expect(holidays.count).to be >= 4
      expect(holidays.pluck(:is_mandatory)).to all(be true)
    end

    it "is idempotent for departments and designations" do
      subject
      # Running again should not duplicate
      expect { described_class.new(company).call }.not_to change(company.departments, :count)
    end
  end
end
