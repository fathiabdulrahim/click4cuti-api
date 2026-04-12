require "rails_helper"

RSpec.describe "Api::V1::Admin::LeaveApplications", type: :request do
  include_context "admin multi-tenant world"

  let!(:leave_policy_a1) { create(:leave_policy, company: company_a1) }
  let!(:leave_policy_a2) { create(:leave_policy, company: company_a2) }
  let!(:leave_policy_b1) { create(:leave_policy, company: company_b1) }

  let!(:leave_type_a1) { create(:leave_type, leave_policy: leave_policy_a1) }
  let!(:leave_type_a2) { create(:leave_type, leave_policy: leave_policy_a2) }
  let!(:leave_type_b1) { create(:leave_type, leave_policy: leave_policy_b1) }

  let!(:user_a1) { create(:user, company: company_a1) }
  let!(:user_a2) { create(:user, company: company_a2) }
  let!(:user_b1) { create(:user, company: company_b1) }

  let!(:resource_a1) { create(:leave_application, user: user_a1, leave_type: leave_type_a1) }
  let!(:resource_a2) { create(:leave_application, user: user_a2, leave_type: leave_type_a2) }
  let!(:resource_b1) { create(:leave_application, user: user_b1, leave_type: leave_type_b1) }

  let(:base_path) { "/api/v1/admin/leave_applications" }
  let(:path_lambda) { ->(resource) { "#{base_path}/#{resource.id}" } }

  describe "GET /api/v1/admin/leave_applications" do
    it_behaves_like "requires admin authentication", :get, "/api/v1/admin/leave_applications"
    it_behaves_like "admin scoped index", "/api/v1/admin/leave_applications"
  end

  describe "GET /api/v1/admin/leave_applications/:id" do
    it_behaves_like "admin cross-tenant show", ->(r) { "/api/v1/admin/leave_applications/#{r.id}" }

    context "as super_admin" do
      it "returns the leave application" do
        get path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(resource_a1.id)
      end
    end
  end

  describe "POST /api/v1/admin/leave_applications" do
    let(:valid_params) do
      {
        leave_application: {
          user_id: user_a1.id,
          leave_type_id: leave_type_a1.id,
          start_date: 2.weeks.from_now.to_date.to_s,
          end_date: (2.weeks.from_now.to_date + 1.day).to_s,
          reason: "Family event",
          total_days: 2.0,
          status: "PENDING"
        }
      }
    end

    context "as super_admin" do
      it "creates a leave application" do
        post base_path, params: valid_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:created)
      end
    end

    context "as company_admin" do
      it "creates a leave application for own company user" do
        post base_path, params: valid_params.to_json, headers: company_a1_headers
        expect(response).to have_http_status(:created)
      end
    end
  end

  describe "PATCH /api/v1/admin/leave_applications/:id" do
    let(:update_params) { { leave_application: { status: "APPROVED", reviewer_remarks: "Looks good" } } }

    it_behaves_like "admin cross-tenant update",
                    ->(r) { "/api/v1/admin/leave_applications/#{r.id}" },
                    { leave_application: { status: "APPROVED", reviewer_remarks: "Ok" } }

    context "as super_admin" do
      it "updates the leave application status" do
        patch path_lambda.call(resource_a1), params: update_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ── Agency admin cannot see leaves from no-agency companies ──────────

  describe "agency admin vs independent (no-agency) company leaves" do
    let!(:independent_company) { create(:company, hr_agency: nil) }
    let!(:ind_policy) { create(:leave_policy, company: independent_company) }
    let!(:ind_type) { create(:leave_type, leave_policy: ind_policy) }
    let!(:ind_user) { create(:user, company: independent_company) }
    let!(:ind_leave) { create(:leave_application, user: ind_user, leave_type: ind_type) }

    it "agency_admin_a does not see leaves from independent company" do
      get "/api/v1/admin/leave_applications", headers: agency_a_headers
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).not_to include(ind_leave.id)
    end

    it "agency_admin_a gets 404 for independent company's leave show" do
      get "/api/v1/admin/leave_applications/#{ind_leave.id}", headers: agency_a_headers
      expect(response).to have_http_status(:not_found)
    end

    it "super_admin CAN see leaves from independent company" do
      get "/api/v1/admin/leave_applications", headers: super_admin_headers
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(ind_leave.id)
    end
  end

  describe "DELETE /api/v1/admin/leave_applications/:id" do
    it_behaves_like "admin cross-tenant destroy", ->(r) { "/api/v1/admin/leave_applications/#{r.id}" }

    context "as super_admin" do
      it "cancels the leave application" do
        delete path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to eq("Application cancelled.")
      end
    end

    context "as company_admin" do
      it "can cancel a leave application in own company" do
        delete path_lambda.call(resource_a1), headers: company_a1_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to eq("Application cancelled.")
      end
    end

    context "as agency_admin" do
      it "cannot destroy a leave application within their scope" do
        delete path_lambda.call(resource_a1), headers: agency_a_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
