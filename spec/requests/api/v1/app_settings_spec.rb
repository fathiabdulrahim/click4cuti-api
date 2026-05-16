require "rails_helper"

RSpec.describe "Api::V1::AppSettings", type: :request do
  let!(:company) { create(:company) }
  let!(:user)    { create(:user, :employee, company: company) }
  let(:headers)  { auth_headers_for_user(user) }

  describe "GET /api/v1/app_settings" do
    it_behaves_like "requires authentication", :get, "/api/v1/app_settings"

    it "returns the 4 default toggles" do
      get "/api/v1/app_settings", headers: headers
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to include(
        "notifications_enabled" => true,
        "clock_in_selfie_enabled" => false,
        "early_late_indicator_enabled" => false,
        "attendance_confirmation_enabled" => false
      )
    end
  end

  describe "PATCH /api/v1/app_settings" do
    it "updates preferences" do
      patch "/api/v1/app_settings",
            params: {
              notifications_enabled: false,
              clock_in_selfie_enabled: true,
              early_late_indicator_enabled: true
            }.to_json,
            headers: headers
      expect(response).to have_http_status(:ok)
      user.reload
      expect(user.notifications_enabled).to be(false)
      expect(user.clock_in_selfie_enabled).to be(true)
      expect(user.early_late_indicator_enabled).to be(true)
    end
  end
end
