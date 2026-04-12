require "rails_helper"

RSpec.describe "Api::V1::Admin::LeaveTypes", type: :request do
  include_context "admin multi-tenant world"

  let!(:policy_a1) { create(:leave_policy, company: company_a1) }
  let!(:policy_a2) { create(:leave_policy, company: company_a2) }
  let!(:policy_b1) { create(:leave_policy, company: company_b1) }

  let!(:resource_a1) { create(:leave_type, leave_policy: policy_a1) }
  let!(:resource_a2) { create(:leave_type, leave_policy: policy_a2) }
  let!(:resource_b1) { create(:leave_type, leave_policy: policy_b1) }

  let(:base_path) { "/api/v1/admin/leave_types" }
  let(:path_lambda) { ->(resource) { "#{base_path}/#{resource.id}" } }

  describe "GET /api/v1/admin/leave_types" do
    it_behaves_like "requires admin authentication", :get, "/api/v1/admin/leave_types"
    it_behaves_like "admin scoped index", "/api/v1/admin/leave_types"
  end

  describe "GET /api/v1/admin/leave_types/:id" do
    it_behaves_like "admin cross-tenant show", ->(r) { "/api/v1/admin/leave_types/#{r.id}" }

    context "as super_admin" do
      it "returns the leave type" do
        get path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(resource_a1.id)
      end
    end
  end

  describe "POST /api/v1/admin/leave_types" do
    let(:valid_params) do
      {
        leave_type: {
          name: "Custom Leave",
          category: "SPECIAL",
          leave_policy_id: policy_a1.id,
          default_days_tier1: 5,
          default_days_tier2: 7,
          default_days_tier3: 10
        }
      }
    end

    context "as super_admin" do
      it "can create a leave type in any company's policy" do
        post base_path, params: valid_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("Custom Leave")
      end
    end

    context "as company_admin" do
      it "can create a leave type in own company's policy" do
        post base_path, params: valid_params.to_json, headers: company_a1_headers
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("Custom Leave")
      end
    end
  end

  describe "PATCH /api/v1/admin/leave_types/:id" do
    let(:update_params) { { leave_type: { name: "Updated Leave" } } }

    it_behaves_like "admin cross-tenant update",
                    ->(r) { "/api/v1/admin/leave_types/#{r.id}" },
                    { leave_type: { name: "Updated Leave" } }

    context "as super_admin" do
      it "updates the leave type" do
        patch path_lambda.call(resource_a1), params: update_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["name"]).to eq("Updated Leave")
      end
    end
  end

  describe "DELETE /api/v1/admin/leave_types/:id" do
    it_behaves_like "admin cross-tenant destroy", ->(r) { "/api/v1/admin/leave_types/#{r.id}" }

    context "as super_admin" do
      it "destroys the leave type" do
        delete path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
