require "rails_helper"

RSpec.describe "Api::V1::Admin::Dashboards", type: :request do
  include_context "admin multi-tenant world"

  let!(:employee_a1) { create(:user, company: company_a1) }

  let(:dashboard_path) { "/api/v1/admin/dashboard" }

  describe "GET /api/v1/admin/dashboard" do
    it_behaves_like "requires admin authentication", :get, "/api/v1/admin/dashboard"

    context "as super_admin" do
      it "returns 200 with dashboard stats" do
        get dashboard_path, headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body).to have_key("total_employees")
        expect(body).to have_key("pending_approvals")
        expect(body).to have_key("on_leave_today")
        expect(body).to have_key("approved_ytd")
        expect(body).to have_key("rejected_ytd")
        expect(body).to have_key("leave_by_type")
        expect(body).to have_key("recent_applications")
      end
    end

    context "as agency_admin" do
      it "returns 200 with dashboard stats" do
        get dashboard_path, headers: agency_a_headers
        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body).to have_key("total_employees")
        expect(body).to have_key("pending_approvals")
      end
    end

    context "as company_admin" do
      it "returns 200 with dashboard stats" do
        get dashboard_path, headers: company_a1_headers
        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body).to have_key("total_employees")
        expect(body).to have_key("pending_approvals")
      end
    end
  end
end
