require "rails_helper"

RSpec.describe "Api::V1::Auth::Passwords", type: :request do
  let!(:user) { create(:user, company: create(:company)) }

  describe "POST /api/v1/auth/password (forgot password)" do
    it "returns 200 for a valid email" do
      post "/api/v1/auth/password",
        params: { user: { email: user.email } }.to_json,
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:ok)
    end

    it "returns 422 for a non-existent email" do
      post "/api/v1/auth/password",
        params: { user: { email: "unknown@example.com" } }.to_json,
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
