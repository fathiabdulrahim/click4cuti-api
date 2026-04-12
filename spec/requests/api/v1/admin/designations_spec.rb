require "rails_helper"

RSpec.describe "Api::V1::Admin::Designations", type: :request do
  include_context "admin multi-tenant world"

  let!(:resource_a1) { create(:designation, company: company_a1) }
  let!(:resource_a2) { create(:designation, company: company_a2) }
  let!(:resource_b1) { create(:designation, company: company_b1) }

  let(:base_path) { "/api/v1/admin/designations" }
  let(:path_lambda) { ->(resource) { "#{base_path}/#{resource.id}" } }

  describe "GET /api/v1/admin/designations" do
    it_behaves_like "requires admin authentication", :get, "/api/v1/admin/designations"
    it_behaves_like "admin scoped index", "/api/v1/admin/designations"
  end

  describe "GET /api/v1/admin/designations/:id" do
    it_behaves_like "admin cross-tenant show", ->(r) { "/api/v1/admin/designations/#{r.id}" }

    context "as super_admin" do
      it "returns the designation" do
        get path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(resource_a1.id)
      end
    end
  end

  describe "POST /api/v1/admin/designations" do
    let(:valid_params) { { designation: { title: "New Title", company_id: company_a1.id } } }

    context "as super_admin" do
      it "can create a designation in any company" do
        post base_path, params: valid_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["title"]).to eq("New Title")
      end
    end

    context "as company_admin" do
      it "can create a designation in own company" do
        post base_path, params: valid_params.to_json, headers: company_a1_headers
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["title"]).to eq("New Title")
      end
    end
  end

  describe "PATCH /api/v1/admin/designations/:id" do
    let(:update_params) { { designation: { title: "Updated" } } }

    it_behaves_like "admin cross-tenant update",
                    ->(r) { "/api/v1/admin/designations/#{r.id}" },
                    { designation: { title: "Updated" } }

    context "as super_admin" do
      it "updates the designation" do
        patch path_lambda.call(resource_a1), params: update_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["title"]).to eq("Updated")
      end
    end
  end

  describe "DELETE /api/v1/admin/designations/:id" do
    it_behaves_like "admin cross-tenant destroy", ->(r) { "/api/v1/admin/designations/#{r.id}" }

    context "as super_admin" do
      it "destroys the designation" do
        delete path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
