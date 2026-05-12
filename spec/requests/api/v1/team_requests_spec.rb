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

    context "with explicit leave_approvers (multi-approver feature)" do
      let!(:explicit_approver) { create(:user, :manager, company: company_a) }
      let!(:non_approver)      { create(:user, :manager, company: company_a) }
      let!(:other_employee)    { create(:user, :employee, company: company_a, manager: manager_a) }
      let!(:other_employee_leave) do
        create(:leave_application, user: other_employee, leave_type: leave_type_a, status: "PENDING")
      end

      before do
        create(:user_leave_approver, user: employee_a, approver: explicit_approver)
      end

      it "an explicit approver sees the applicant's pending leave" do
        get "/api/v1/team_requests", headers: auth_headers_for_user(explicit_approver)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(leave_pending.id)
      end

      it "a non-listed manager does not see the applicant" do
        get "/api/v1/team_requests", headers: auth_headers_for_user(non_approver)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).not_to include(leave_pending.id)
      end

      it "the original reporting manager NO LONGER sees the applicant once explicit approvers are set" do
        get "/api/v1/team_requests", headers: auth_headers_for_user(manager_a)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).not_to include(leave_pending.id)
      end

      it "the reporting manager still sees subordinates who DON'T have explicit approvers (fallback intact)" do
        get "/api/v1/team_requests", headers: auth_headers_for_user(manager_a)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(other_employee_leave.id)
      end
    end
  end

  describe "PATCH /api/v1/team_requests/:id" do
    let!(:explicit_approver) { create(:user, :manager, company: company_a) }
    let!(:other_manager)     { create(:user, :manager, company: company_a) }
    let!(:leave_balance_a) do
      create(:leave_balance,
             user: employee_a, leave_type: leave_type_a,
             year: Date.current.year,
             total_entitled: 12.0, remaining_days: 10.0,
             used_days: 0.0, pending_days: 2.0)
    end

    before do
      allow(LeaveNotificationJob).to receive(:perform_later)
      create(:user_leave_approver, user: employee_a, approver: explicit_approver)
    end

    it "allows the explicit approver to approve" do
      patch "/api/v1/team_requests/#{leave_pending.id}",
            params: { leave: { status: "APPROVED" } }.to_json,
            headers: auth_headers_for_user(explicit_approver).merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:ok)
      expect(leave_pending.reload.status).to eq("approved")
      expect(leave_pending.approver).to eq(explicit_approver)
    end

    it "forbids a non-listed manager from approving" do
      patch "/api/v1/team_requests/#{leave_pending.id}",
            params: { leave: { status: "APPROVED" } }.to_json,
            headers: auth_headers_for_user(other_manager).merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:forbidden)
      expect(leave_pending.reload.status).to eq("pending")
    end

    it "forbids the applicant from self-approving" do
      patch "/api/v1/team_requests/#{leave_pending.id}",
            params: { leave: { status: "APPROVED" } }.to_json,
            headers: auth_headers_for_user(employee_a).merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:forbidden)
    end
  end
end
