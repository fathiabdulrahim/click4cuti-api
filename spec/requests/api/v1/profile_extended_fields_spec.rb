require "rails_helper"

RSpec.describe "Api::V1::Profile extended fields", type: :request do
  let!(:company) { create(:company) }
  let!(:user)    { create(:user, :employee, company: company) }
  let(:headers)  { auth_headers_for_user(user) }

  describe "PATCH /api/v1/profile" do
    it_behaves_like "requires authentication", :patch, "/api/v1/profile"

    it "updates NRIC, DOB, marital_status, and other identity fields" do
      patch "/api/v1/profile",
            params: {
              first_name: "Nur",
              last_name: "Fatin",
              nric: "990413087390",
              nric_color: "BLUE",
              date_of_birth: "1999-04-13",
              race: "MALAY",
              religion: "ISLAM",
              marital_status: "SINGLE",
              nationality: "CITIZEN",
              bumi_status: "BUMIPUTERA",
              driving_license_number: "DL12345",
              driving_license_class: "D",
              driving_license_expiry: "2030-01-01"
            }.to_json,
            headers: headers
      expect(response).to have_http_status(:ok)
      user.reload
      expect(user.nric).to eq("990413087390")
      expect(user.date_of_birth.to_s).to eq("1999-04-13")
      expect(user.marital_status).to eq("single")           # enum returns key
      expect(user.bumi_status).to eq("bumiputera")
      expect(user.driving_license_class).to eq("D")
    end

    it "returns 422 for an invalid enum value" do
      patch "/api/v1/profile",
            params: { marital_status: "INVALID" }.to_json,
            headers: headers
      expect(response.status).to eq(422).or eq(400)
    end
  end
end
