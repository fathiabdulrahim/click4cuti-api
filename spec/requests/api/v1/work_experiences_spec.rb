require "rails_helper"

RSpec.describe "Api::V1::WorkExperiences", type: :request do
  let!(:company_a) { create(:company) }
  let!(:company_b) { create(:company) }
  let!(:employee_a) { create(:user, :employee, company: company_a) }
  let!(:employee_b) { create(:user, :employee, company: company_b) }
  let!(:we_a) { create(:work_experience, user: employee_a, company_name: "Acme Sdn Bhd") }
  let!(:we_b) { create(:work_experience, user: employee_b, company_name: "Beta Sdn Bhd") }

  let(:employee_a_headers) { auth_headers_for_user(employee_a) }
  let(:employee_b_headers) { auth_headers_for_user(employee_b) }

  describe "GET /api/v1/work_experiences" do
    it_behaves_like "requires authentication", :get, "/api/v1/work_experiences"

    it "lists only own work experiences" do
      get "/api/v1/work_experiences", headers: employee_a_headers
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(we_a.id)
      expect(ids).not_to include(we_b.id)
    end
  end

  describe "POST /api/v1/work_experiences" do
    let(:valid_params) do
      { work_experience: { company_name: "New Co", position: "Engineer", start_date: "2020-01-01", end_date: "2022-12-31" } }
    end

    it "creates a work experience for self" do
      expect {
        post "/api/v1/work_experiences", params: valid_params.to_json, headers: employee_a_headers
      }.to change { employee_a.work_experiences.count }.by(1)
      expect(response).to have_http_status(:created)
    end

    it "returns 422 with invalid params" do
      post "/api/v1/work_experiences",
           params: { work_experience: { company_name: "" } }.to_json,
           headers: employee_a_headers
      expect(response).to have_http_status(:unprocessable_content).or have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/work_experiences/:id" do
    it "updates own work experience" do
      patch "/api/v1/work_experiences/#{we_a.id}",
            params: { work_experience: { position: "Senior Engineer" } }.to_json,
            headers: employee_a_headers
      expect(response).to have_http_status(:ok)
      expect(we_a.reload.position).to eq("Senior Engineer")
    end

    it "forbids editing another company's record" do
      patch "/api/v1/work_experiences/#{we_b.id}",
            params: { work_experience: { position: "Hacker" } }.to_json,
            headers: employee_a_headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/work_experiences/:id" do
    it "deletes own work experience" do
      expect {
        delete "/api/v1/work_experiences/#{we_a.id}", headers: employee_a_headers
      }.to change(WorkExperience, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
