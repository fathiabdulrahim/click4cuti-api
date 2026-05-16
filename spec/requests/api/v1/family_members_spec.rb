require "rails_helper"

RSpec.describe "Api::V1::FamilyMembers", type: :request do
  let!(:company_a) { create(:company) }
  let!(:company_b) { create(:company) }
  let!(:employee_a) { create(:user, :employee, company: company_a) }
  let!(:employee_b) { create(:user, :employee, company: company_b) }
  let!(:fm_a) { create(:family_member, user: employee_a, first_name: "Ali") }
  let!(:fm_b) { create(:family_member, user: employee_b, first_name: "Bob") }

  let(:headers_a) { auth_headers_for_user(employee_a) }

  describe "GET /api/v1/family_members" do
    it_behaves_like "requires authentication", :get, "/api/v1/family_members"

    it "lists own family members only" do
      get "/api/v1/family_members", headers: headers_a
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(fm_a.id)
      expect(ids).not_to include(fm_b.id)
    end
  end

  describe "POST /api/v1/family_members" do
    it "creates a family member" do
      expect {
        post "/api/v1/family_members",
             params: {
               family_member: {
                 relation: "SPOUSE",
                 first_name: "Aisyah",
                 last_name: "Binti Abdullah",
                 gender: "FEMALE",
                 date_of_birth: "1995-01-01",
                 employment_status: "WORKING"
               }
             }.to_json,
             headers: headers_a
      }.to change { employee_a.family_members.count }.by(1)
      expect(response).to have_http_status(:created)
    end

    it "rejects invalid relation" do
      post "/api/v1/family_members",
           params: {
             family_member: {
               relation: "INVALID",
               first_name: "X",
               gender: "MALE",
               date_of_birth: "2000-01-01",
               employment_status: "WORKING"
             }
           }.to_json,
           headers: headers_a
      expect(response.status).to eq(422).or eq(400)
    end
  end

  describe "PATCH /api/v1/family_members/:id" do
    it "updates own family member" do
      patch "/api/v1/family_members/#{fm_a.id}",
            params: { family_member: { first_name: "Updated" } }.to_json,
            headers: headers_a
      expect(response).to have_http_status(:ok)
      expect(fm_a.reload.first_name).to eq("Updated")
    end

    it "forbids editing another user's family member" do
      patch "/api/v1/family_members/#{fm_b.id}",
            params: { family_member: { first_name: "Hacked" } }.to_json,
            headers: headers_a
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/family_members/:id" do
    it "deletes own family member" do
      expect {
        delete "/api/v1/family_members/#{fm_a.id}", headers: headers_a
      }.to change(FamilyMember, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
