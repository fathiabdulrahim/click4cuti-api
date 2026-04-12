require "rails_helper"

RSpec.describe "Api::V1::LeaveBalances", type: :request do
  let!(:company_a) { create(:company) }
  let!(:company_b) { create(:company) }
  let!(:policy_a) { create(:leave_policy, company: company_a) }
  let!(:leave_type_a) { create(:leave_type, leave_policy: policy_a) }
  let!(:policy_b) { create(:leave_policy, company: company_b) }
  let!(:leave_type_b) { create(:leave_type, leave_policy: policy_b, name: "Annual Leave B") }

  let!(:employee_a) { create(:user, :employee, company: company_a) }
  let!(:employee_b) { create(:user, :employee, company: company_b) }
  let!(:manager_a) { create(:user, :manager, company: company_a) }

  before { employee_a.update!(manager: manager_a) }

  let!(:balance_a) { create(:leave_balance, user: employee_a, leave_type: leave_type_a) }
  let!(:balance_mgr) { create(:leave_balance, user: manager_a, leave_type: leave_type_a) }
  let!(:balance_b) { create(:leave_balance, user: employee_b, leave_type: leave_type_b) }

  describe "GET /api/v1/leave_balances" do
    it_behaves_like "requires authentication", :get, "/api/v1/leave_balances"

    context "as employee" do
      it "sees only own balances" do
        get "/api/v1/leave_balances", headers: auth_headers_for_user(employee_a)
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(balance_a.id)
        expect(ids).not_to include(balance_mgr.id, balance_b.id)
      end
    end

    context "as manager" do
      it "sees own and subordinates' balances" do
        get "/api/v1/leave_balances", headers: auth_headers_for_user(manager_a)
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(balance_a.id, balance_mgr.id)
        expect(ids).not_to include(balance_b.id)
      end
    end

    context "cross-company isolation" do
      it "employee B cannot see company A balances" do
        get "/api/v1/leave_balances", headers: auth_headers_for_user(employee_b)
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(balance_b.id)
        expect(ids).not_to include(balance_a.id, balance_mgr.id)
      end
    end
  end
end
