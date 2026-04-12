require "rails_helper"

RSpec.describe "Api::V1::Admin::Departments", type: :request do
  include_context "admin multi-tenant world"

  let!(:resource_a1) { create(:department, company: company_a1) }
  let!(:resource_a2) { create(:department, company: company_a2) }
  let!(:resource_b1) { create(:department, company: company_b1) }

  let(:base_path) { "/api/v1/admin/departments" }
  let(:path_lambda) { ->(resource) { "#{base_path}/#{resource.id}" } }

  describe "GET /api/v1/admin/departments" do
    it_behaves_like "requires admin authentication", :get, "/api/v1/admin/departments"
    it_behaves_like "admin scoped index", "/api/v1/admin/departments"
  end

  describe "GET /api/v1/admin/departments/:id" do
    it_behaves_like "admin cross-tenant show", ->(r) { "/api/v1/admin/departments/#{r.id}" }

    context "as super_admin" do
      it "returns the department" do
        get path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(resource_a1.id)
      end
    end
  end

  describe "POST /api/v1/admin/departments" do
    let(:valid_params) { { department: { name: "New Dept", company_id: company_a1.id } } }

    context "as super_admin" do
      it "can create a department in any company" do
        post base_path, params: valid_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("New Dept")
      end
    end

    context "as company_admin" do
      it "can create a department in own company" do
        post base_path, params: valid_params.to_json, headers: company_a1_headers
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("New Dept")
      end
    end
  end

  describe "PATCH /api/v1/admin/departments/:id" do
    let(:update_params) { { department: { name: "Updated Dept" } } }

    it_behaves_like "admin cross-tenant update",
                    ->(r) { "/api/v1/admin/departments/#{r.id}" },
                    { department: { name: "Updated Dept" } }

    context "as super_admin" do
      it "updates the department" do
        patch path_lambda.call(resource_a1), params: update_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["name"]).to eq("Updated Dept")
      end
    end
  end

  describe "DELETE /api/v1/admin/departments/:id" do
    it_behaves_like "admin cross-tenant destroy", ->(r) { "/api/v1/admin/departments/#{r.id}" }

    context "as super_admin" do
      it "destroys the department" do
        delete path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
