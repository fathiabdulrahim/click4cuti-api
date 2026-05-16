require "rails_helper"

RSpec.describe "Api::V1::Admin::WarningLetters (Conduct Records)", type: :request do
  include_context "admin multi-tenant world"

  let!(:user)       { create(:user, :employee, company: company_a1) }
  let!(:leave_type) { create(:leave_type, leave_policy: create(:leave_policy, company: company_a1)) }
  let!(:auto_letter) do
    create(:warning_letter,
           user: user, company: company_a1, leave_type: leave_type,
           source: "AUTO", year: Date.current.year, reason: "EL > 3", issued_date: Date.current)
  end

  describe "POST /api/v1/admin/warning_letters (manual conduct entry)" do
    it "creates a MANUAL conduct record" do
      expect {
        post "/api/v1/admin/warning_letters",
             params: {
               warning_letter: {
                 user_id: user.id,
                 reason: "Repeated tardiness",
                 details: "Late 5 times in November",
                 action_taken: "Verbal warning issued",
                 issued_date: Date.current
               }
             }.to_json,
             headers: company_a1_headers
      }.to change(WarningLetter, :count).by(1)
      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["source"]).to eq("manual")
      expect(body["issued_by_id"]).to eq(company_admin_a1.id)
    end
  end

  describe "PATCH /api/v1/admin/warning_letters/:id" do
    it "edits a MANUAL record's details" do
      manual = create(:warning_letter,
                      user: user, company: company_a1, leave_type: nil,
                      source: "MANUAL", year: Date.current.year,
                      reason: "Tardy", issued_date: Date.current,
                      issued_by_id: company_admin_a1.id)
      patch "/api/v1/admin/warning_letters/#{manual.id}",
            params: { warning_letter: { details: "Updated detail" } }.to_json,
            headers: company_a1_headers
      expect(response).to have_http_status(:ok)
      expect(manual.reload.details).to eq("Updated detail")
    end

    it "AUTO records still acknowledge on update" do
      patch "/api/v1/admin/warning_letters/#{auto_letter.id}",
            params: {}.to_json,
            headers: company_a1_headers
      expect(response).to have_http_status(:ok)
      expect(auto_letter.reload.acknowledged).to be(true)
    end
  end
end
