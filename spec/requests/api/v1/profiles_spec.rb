require "rails_helper"

RSpec.describe "Api::V1::Profiles", type: :request do
  let!(:company) { create(:company) }
  let!(:user) { create(:user, company: company) }
  let(:headers) { auth_headers_for_user(user) }

  describe "GET /api/v1/profile" do
    it_behaves_like "requires authentication", :get, "/api/v1/profile"

    it "returns the current user's profile" do
      get "/api/v1/profile", headers: headers
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["id"]).to eq(user.id)
      expect(body["email"]).to eq(user.email)
      expect(body["full_name"]).to eq(user.full_name)
    end
  end

  describe "PATCH /api/v1/profile" do
    it_behaves_like "requires authentication", :patch, "/api/v1/profile"

    it "updates the current user's profile" do
      patch "/api/v1/profile",
        params: { full_name: "Updated Name", phone: "0123456789" }.to_json,
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["full_name"]).to eq("Updated Name")
      expect(response.parsed_body["phone"]).to eq("0123456789")
    end

    it "does not allow updating role" do
      patch "/api/v1/profile",
        params: { role: "ADMIN" }.to_json,
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(user.reload.role).to eq("employee")
    end
  end
end
