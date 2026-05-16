require "rails_helper"

RSpec.describe "Api::V1::Admin Claims", type: :request do
  include_context "admin multi-tenant world"

  let!(:user)         { create(:user, :employee, company: company_a1) }
  let!(:claim_type)   { create(:claim_type, company: company_a1, name: "Meal") }
  let!(:claim_type_b) { create(:claim_type, company: company_b1, name: "Meal") }

  describe "Admin::ClaimTypes" do
    it "lists claim types scoped to company" do
      get "/api/v1/admin/claim_types", headers: company_a1_headers
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(claim_type.id)
      expect(ids).not_to include(claim_type_b.id)
    end

    it "creates a claim type" do
      expect {
        post "/api/v1/admin/claim_types",
             params: { claim_type: { name: "Mileage", default_annual_limit: 6000 } }.to_json,
             headers: company_a1_headers
      }.to change(ClaimType, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "soft-deletes (is_active=false)" do
      delete "/api/v1/admin/claim_types/#{claim_type.id}", headers: company_a1_headers
      expect(response).to have_http_status(:no_content)
      expect(claim_type.reload.is_active).to be(false)
    end
  end

  describe "Admin::ClaimPolicies (per-user)" do
    it "lazy-creates one policy row per active claim type" do
      get "/api/v1/admin/users/#{user.id}/claim_policies", headers: company_a1_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(1)
      expect(response.parsed_body.first["claim_type_id"]).to eq(claim_type.id)
    end

    it "updates an existing policy row" do
      policy = create(:user_claim_policy, user: user, claim_type: claim_type, annual_limit: 1000)
      patch "/api/v1/admin/users/#{user.id}/claim_policies/#{policy.id}",
            params: { user_claim_policy: { annual_limit: 2500, is_included: false } }.to_json,
            headers: company_a1_headers
      expect(response).to have_http_status(:ok)
      policy.reload
      expect(policy.annual_limit.to_i).to eq(2500)
      expect(policy.is_included).to be(false)
    end
  end

  describe "Admin::ClaimApplications" do
    it "creates a historical claim record" do
      expect {
        post "/api/v1/admin/users/#{user.id}/claim_applications",
             params: {
               claim_application: {
                 claim_type_id: claim_type.id,
                 amount: 120.50,
                 claim_date: Date.current,
                 reason: "Team lunch"
               }
             }.to_json,
             headers: company_a1_headers
      }.to change(ClaimApplication, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe "Admin::ClaimBalances" do
    it "lists balances for a user/year (empty when none seeded)" do
      get "/api/v1/admin/users/#{user.id}/claim_balances", headers: company_a1_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end
  end
end
