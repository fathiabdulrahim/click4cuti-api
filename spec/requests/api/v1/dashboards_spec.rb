require "rails_helper"

RSpec.describe "Api::V1::Dashboards", type: :request do
  let!(:company) { create(:company) }
  let!(:leave_policy) { create(:leave_policy, company: company) }
  let!(:leave_type) { create(:leave_type, leave_policy: leave_policy) }
  let!(:user) { create(:user, company: company) }
  let!(:leave_balance) { create(:leave_balance, user: user, leave_type: leave_type) }
  let(:headers) { auth_headers_for_user(user) }

  describe "GET /api/v1/dashboard" do
    it_behaves_like "requires authentication", :get, "/api/v1/dashboard"

    it "returns dashboard stats for the current user" do
      get "/api/v1/dashboard", headers: headers
      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body).to have_key("leave_balances")
      expect(body).to have_key("pending_requests")
      expect(body).to have_key("approved_this_year")
    end
  end
end
