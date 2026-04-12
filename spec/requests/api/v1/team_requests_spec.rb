require "rails_helper"

RSpec.describe "Api::V1::TeamRequests", type: :request do
  let!(:company_a) { create(:company) }
  let!(:company_b) { create(:company) }
  let!(:policy_a) { create(:leave_policy, company: company_a) }
  let!(:leave_type_a) { create(:leave_type, leave_policy: policy_a) }

  let!(:manager_a) { create(:user, :manager, company: company_a) }
  let!(:employee_a) { create(:user, :employee, company: company_a, manager: manager_a) }
  let!(:admin_a) { create(:user, :admin, company: company_a) }
  let!(:employee_b) { create(:user, :employee, company: company_b) }

  let!(:leave_pending) do
    create(:leave_application, user: employee_a, leave_type: leave_type_a, status: "PENDING")
  end

  let!(:policy_b) { create(:leave_policy, company: company_b) }
  let!(:leave_type_b) { create(:leave_type, leave_policy: policy_b, name: "Annual B") }
  let!(:leave_b) do
    create(:leave_application, user: employee_b, leave_type: leave_type_b, status: "PENDING")
  end

  describe "GET /api/v1/team_requests" do
    it_behaves_like "requires authentication", :get, "/api/v1/team_requests"

    context "as manager" do
      it "sees pending leaves from subordinates" do
        get "/api/v1/team_requests", headers: auth_headers_for_user(manager_a)
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(leave_pending.id)
        expect(ids).not_to include(leave_b.id)
      end
    end

    context "as admin (user role)" do
      it "sees all pending leaves in company" do
        get "/api/v1/team_requests", headers: auth_headers_for_user(admin_a)
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(leave_pending.id)
        expect(ids).not_to include(leave_b.id)
      end
    end

    context "as employee" do
      it "sees only own pending leaves (scoped via LeaveApplicationPolicy)" do
        get "/api/v1/team_requests", headers: auth_headers_for_user(employee_a)
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(leave_pending.id)
        expect(ids).not_to include(leave_b.id)
      end
    end

    context "cross-company" do
      it "manager cannot see other company's pending leaves" do
        get "/api/v1/team_requests", headers: auth_headers_for_user(manager_a)
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).not_to include(leave_b.id)
      end
    end
  end
end
