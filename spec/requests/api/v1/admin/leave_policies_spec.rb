require "rails_helper"

RSpec.describe "Api::V1::Admin::LeavePolicies", type: :request do
  include_context "admin multi-tenant world"

  let!(:resource_a1) { create(:leave_policy, company: company_a1) }
  let!(:resource_a2) { create(:leave_policy, company: company_a2) }
  let!(:resource_b1) { create(:leave_policy, company: company_b1) }

  let(:base_path) { "/api/v1/admin/leave_policies" }
  let(:path_lambda) { ->(resource) { "#{base_path}/#{resource.id}" } }

  describe "GET /api/v1/admin/leave_policies" do
    it_behaves_like "requires admin authentication", :get, "/api/v1/admin/leave_policies"
    it_behaves_like "admin scoped index", "/api/v1/admin/leave_policies"
  end

  describe "GET /api/v1/admin/leave_policies/:id" do
    it_behaves_like "admin cross-tenant show", ->(r) { "/api/v1/admin/leave_policies/#{r.id}" }

    context "as super_admin" do
      it "returns the leave policy" do
        get path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(resource_a1.id)
      end
    end
  end

  describe "POST /api/v1/admin/leave_policies" do
    let(:valid_params) { { leave_policy: { name: "New Policy", company_id: company_a1.id } } }

    context "as super_admin" do
      it "can create a leave policy in any company" do
        post base_path, params: valid_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("New Policy")
      end
    end

    context "as company_admin" do
      it "can create a leave policy in own company" do
        post base_path, params: valid_params.to_json, headers: company_a1_headers
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("New Policy")
      end
    end
  end

  describe "PATCH /api/v1/admin/leave_policies/:id" do
    let(:update_params) { { leave_policy: { name: "Updated" } } }

    it_behaves_like "admin cross-tenant update",
                    ->(r) { "/api/v1/admin/leave_policies/#{r.id}" },
                    { leave_policy: { name: "Updated" } }

    context "as super_admin" do
      it "updates the leave policy" do
        patch path_lambda.call(resource_a1), params: update_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["name"]).to eq("Updated")
      end
    end
  end

  describe "DELETE /api/v1/admin/leave_policies/:id" do
    it_behaves_like "admin cross-tenant destroy", ->(r) { "/api/v1/admin/leave_policies/#{r.id}" }

    context "as super_admin" do
      it "destroys the leave policy" do
        delete path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
