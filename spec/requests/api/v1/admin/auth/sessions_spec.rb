require "rails_helper"

RSpec.describe "Api::V1::Admin::Auth::Sessions", type: :request do
  let!(:admin) { create(:admin_user, :super_admin, password: "Password123!") }

  describe "POST /api/v1/admin/auth/sign_in" do
    let(:valid_params) { { admin_user: { email: admin.email, password: "Password123!" } } }

    it "returns 200 with admin user data and JWT token" do
      post "/api/v1/admin/auth/sign_in", params: valid_params.to_json,
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to be_present

      body = response.parsed_body
      expect(body["admin_user"]["id"]).to eq(admin.id)
      expect(body["admin_user"]["email"]).to eq(admin.email)
      expect(body["admin_user"]["full_name"]).to eq(admin.full_name)
      expect(body["admin_user"]["scope"]).to eq("SUPER_ADMIN")
    end

    it "returns 401 with invalid password" do
      post "/api/v1/admin/auth/sign_in",
        params: { admin_user: { email: admin.email, password: "wrong" } }.to_json,
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with non-existent email" do
      post "/api/v1/admin/auth/sign_in",
        params: { admin_user: { email: "noone@example.com", password: "Password123!" } }.to_json,
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/admin/auth/sign_out" do
    it "returns 200 and revokes the JWT" do
      headers = auth_headers_for_admin(admin)
      delete "/api/v1/admin/auth/sign_out", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to match(/logged out/i)
    end

    it "returns 200 even without a token (Devise default)" do
      delete "/api/v1/admin/auth/sign_out",
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:ok)
    end
  end
end
