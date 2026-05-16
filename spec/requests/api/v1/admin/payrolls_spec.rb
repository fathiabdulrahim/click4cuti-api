require "rails_helper"

RSpec.describe "Api::V1::Admin::Payrolls", type: :request do
  include_context "admin multi-tenant world"

  let!(:user) { create(:user, :employee, company: company_a1) }

  describe "GET .../payroll" do
    it "returns empty payroll for a new user" do
      get "/api/v1/admin/users/#{user.id}/payroll", headers: company_a1_headers
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["user_id"]).to eq(user.id)
      expect(body["bank_detail"]).to be_nil
      expect(body["statutory_detail"]).to be_nil
      expect(body["tax_relief"]).to be_nil
    end
  end

  describe "PATCH .../payroll (composite)" do
    it "creates all three 1:1 records in one request" do
      payload = {
        payroll: {
          bank_detail: {
            bank_name: "Maybank", account_number: "1122334455", account_type: "SAVING",
            branch: "KL", account_status: "ACTIVE"
          },
          statutory_detail: {
            epf_number: "12345678", epf_contribution_start: "AFTER_2001_AUG",
            socso_number: "111222333", income_tax_number: "SG1234"
          },
          tax_relief: {
            spouse_is_working: false, contributes_to_sip: true, tax_category: "REGULAR"
          }
        }
      }
      patch "/api/v1/admin/users/#{user.id}/payroll",
            params: payload.to_json,
            headers: company_a1_headers
      expect(response).to have_http_status(:ok)
      user.reload
      expect(user.bank_detail.bank_name).to eq("Maybank")
      expect(user.statutory_detail.epf_number).to eq("12345678")
      expect(user.tax_relief.tax_category).to eq("regular")  # enum returns key
    end

    it "updates existing 1:1 records" do
      create(:user_bank_detail, user: user, bank_name: "OldBank")
      patch "/api/v1/admin/users/#{user.id}/payroll",
            params: { payroll: { bank_detail: { bank_name: "NewBank" } } }.to_json,
            headers: company_a1_headers
      expect(response).to have_http_status(:ok)
      expect(user.bank_detail.reload.bank_name).to eq("NewBank")
    end
  end
end
