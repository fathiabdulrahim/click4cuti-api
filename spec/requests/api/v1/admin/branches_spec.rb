require "rails_helper"

RSpec.describe "Api::V1::Admin::Branches", type: :request do
  include_context "admin multi-tenant world"

  let!(:resource_a1) { create(:branch, company: company_a1, name: "KL HQ") }
  let!(:resource_a2) { create(:branch, company: company_a2, name: "PJ Branch") }
  let!(:resource_b1) { create(:branch, company: company_b1, name: "JB Branch") }

  describe "GET /api/v1/admin/branches" do
    it_behaves_like "requires admin authentication", :get, "/api/v1/admin/branches"

    it "scopes to admin's company for company admin" do
      get "/api/v1/admin/branches", headers: company_a1_headers
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(resource_a1.id)
      expect(ids).not_to include(resource_a2.id, resource_b1.id)
    end

    it "scopes to all agency companies for agency admin" do
      get "/api/v1/admin/branches", headers: agency_a_headers
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(resource_a1.id, resource_a2.id)
      expect(ids).not_to include(resource_b1.id)
    end

    it "returns all for super_admin" do
      get "/api/v1/admin/branches", headers: super_admin_headers
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(resource_a1.id, resource_a2.id, resource_b1.id)
    end
  end

  describe "POST /api/v1/admin/branches" do
    it "creates a branch for the admin's company" do
      expect {
        post "/api/v1/admin/branches",
             params: { branch: { name: "New Branch" } }.to_json,
             headers: company_a1_headers
      }.to change(Branch, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(Branch.last.company_id).to eq(company_a1.id)
    end
  end

  describe "PATCH /api/v1/admin/branches/:id" do
    it "updates branch" do
      patch "/api/v1/admin/branches/#{resource_a1.id}",
            params: { branch: { name: "Updated Name" } }.to_json,
            headers: company_a1_headers
      expect(response).to have_http_status(:ok)
      expect(resource_a1.reload.name).to eq("Updated Name")
    end
  end

  describe "DELETE /api/v1/admin/branches/:id" do
    it "soft-deletes by setting is_active=false" do
      delete "/api/v1/admin/branches/#{resource_a1.id}", headers: company_a1_headers
      expect(response).to have_http_status(:no_content)
      expect(resource_a1.reload.is_active).to be(false)
    end
  end
end
