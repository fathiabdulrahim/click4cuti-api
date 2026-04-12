require "rails_helper"

RSpec.describe "Api::V1::PublicHolidays", type: :request do
  let!(:company_a) { create(:company) }
  let!(:company_b) { create(:company) }
  let!(:user_a) { create(:user, company: company_a) }
  let!(:user_b) { create(:user, company: company_b) }

  let!(:holiday_a) { create(:public_holiday, company: company_a, name: "Hari Raya") }
  let!(:holiday_b) { create(:public_holiday, company: company_b, name: "Christmas") }

  describe "GET /api/v1/public_holidays" do
    it_behaves_like "requires authentication", :get, "/api/v1/public_holidays"

    it "returns holidays for the current user's company only" do
      get "/api/v1/public_holidays", headers: auth_headers_for_user(user_a)
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(holiday_a.id)
      expect(ids).not_to include(holiday_b.id)
    end

    it "user from company B sees only their company holidays" do
      get "/api/v1/public_holidays", headers: auth_headers_for_user(user_b)
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(holiday_b.id)
      expect(ids).not_to include(holiday_a.id)
    end
  end
end
