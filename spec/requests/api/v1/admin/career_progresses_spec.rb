require "rails_helper"

RSpec.describe "Api::V1::Admin::CareerProgresses", type: :request do
  include_context "admin multi-tenant world"

  let!(:user_a1) { create(:user, :employee, company: company_a1) }
  let!(:user_b1) { create(:user, :employee, company: company_b1) }
  let!(:cp_a1)   { create(:career_progress, user: user_a1, company: company_a1, job_title: "Engineer") }
  let!(:cp_b1)   { create(:career_progress, user: user_b1, company: company_b1, job_title: "Manager") }

  describe "GET .../career_progresses" do
    it "lists career progresses for the user, scoped by tenant" do
      get "/api/v1/admin/users/#{user_a1.id}/career_progresses", headers: company_a1_headers
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(cp_a1.id)
    end

    it "denies access to a different tenant's user" do
      get "/api/v1/admin/users/#{user_b1.id}/career_progresses", headers: company_a1_headers
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).not_to include(cp_b1.id)
    end
  end

  describe "POST .../career_progresses" do
    it "creates a new career progress record" do
      expect {
        post "/api/v1/admin/users/#{user_a1.id}/career_progresses",
             params: {
               career_progress: {
                 job_title: "Senior Engineer",
                 effective_date: "2025-01-01",
                 job_type: "PERMANENT",
                 description: "Promotion"
               }
             }.to_json,
             headers: company_a1_headers
      }.to change(CareerProgress, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end
end
