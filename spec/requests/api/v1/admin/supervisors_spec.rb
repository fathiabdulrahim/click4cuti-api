require "rails_helper"

RSpec.describe "Api::V1::Admin::Supervisors", type: :request do
  include_context "admin multi-tenant world"

  let!(:user_a1)    { create(:user, :employee, company: company_a1) }
  let!(:supervisor) { create(:user, :manager,  company: company_a1) }
  let!(:other_user) { create(:user, :manager,  company: company_b1) }

  let(:base_path) { "/api/v1/admin/users/#{user_a1.id}/supervisors" }

  describe "POST .../supervisors" do
    it "assigns a Level-1 LEAVE supervisor" do
      expect {
        post base_path,
             params: { supervisor: { supervisor_id: supervisor.id, category: "LEAVE", level: 1 } }.to_json,
             headers: company_a1_headers
      }.to change(UserSupervisor, :count).by(1)
      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["category"]).to eq("leave")     # enum returns key
      expect(body["level"]).to eq(1)
      expect(body["supervisor_id"]).to eq(supervisor.id)
    end

    it "rejects self-assignment via check constraint / validation" do
      post base_path,
           params: { supervisor: { supervisor_id: user_a1.id, category: "LEAVE", level: 1 } }.to_json,
           headers: company_a1_headers
      expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:unprocessable_content)
    end

    it "rejects duplicate category+level assignment" do
      create(:user_supervisor, user: user_a1, supervisor: supervisor, category: "CLAIM", level: 1)
      post base_path,
           params: { supervisor: { supervisor_id: supervisor.id, category: "CLAIM", level: 1 } }.to_json,
           headers: company_a1_headers
      expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:unprocessable_content)
    end
  end

  describe "GET .../supervisors" do
    let!(:assignment) { create(:user_supervisor, user: user_a1, supervisor: supervisor, category: "LEAVE", level: 1) }

    it "lists supervisor assignments for the user" do
      get base_path, headers: company_a1_headers
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(assignment.id)
    end
  end

  describe "DELETE .../supervisors/:id" do
    let!(:assignment) { create(:user_supervisor, user: user_a1, supervisor: supervisor, category: "LEAVE", level: 1) }

    it "removes the assignment" do
      expect {
        delete "#{base_path}/#{assignment.id}", headers: company_a1_headers
      }.to change(UserSupervisor, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
