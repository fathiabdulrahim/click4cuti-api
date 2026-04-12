require "rails_helper"

RSpec.describe "Api::V1::Auth::Sessions", type: :request do
  let!(:company) { create(:company) }
  let!(:user) { create(:user, company: company, password: "Password123!") }

  describe "POST /api/v1/auth/sign_in" do
    let(:valid_params) { { user: { email: user.email, password: "Password123!" } } }

    it "returns 200 with user data and JWT token" do
      post "/api/v1/auth/sign_in", params: valid_params.to_json,
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to be_present
      expect(response.headers["Authorization"]).to start_with("Bearer ")

      body = response.parsed_body
      expect(body["user"]["id"]).to eq(user.id)
      expect(body["user"]["email"]).to eq(user.email)
      expect(body["user"]["full_name"]).to eq(user.full_name)
      expect(body["user"]["role"]).to be_present
      expect(body["user"]["company_id"]).to eq(company.id)
    end

    it "returns 401 with invalid password" do
      post "/api/v1/auth/sign_in",
        params: { user: { email: user.email, password: "wrong" } }.to_json,
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with non-existent email" do
      post "/api/v1/auth/sign_in",
        params: { user: { email: "noone@example.com", password: "Password123!" } }.to_json,
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/sign_out" do
    it "returns 200 and revokes the JWT" do
      headers = auth_headers_for_user(user)
      delete "/api/v1/auth/sign_out", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to match(/logged out/i)
    end

    it "returns 200 even without a token (Devise default)" do
      delete "/api/v1/auth/sign_out",
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:ok)
    end
  end
end
