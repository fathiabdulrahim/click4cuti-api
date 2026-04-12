require "rails_helper"

RSpec.describe "Api::V1::Admin::Auth::Passwords", type: :request do
  let!(:admin) { create(:admin_user, :super_admin) }

  describe "POST /api/v1/admin/auth/password (forgot password)" do
    it "returns 200 for a valid email" do
      post "/api/v1/admin/auth/password",
        params: { admin_user: { email: admin.email } }.to_json,
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:ok)
    end

    it "returns 422 for a non-existent email" do
      post "/api/v1/admin/auth/password",
        params: { admin_user: { email: "unknown@example.com" } }.to_json,
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
