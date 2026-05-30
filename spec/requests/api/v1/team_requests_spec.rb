require "rails_helper"

RSpec.describe "/api/v1/team_requests", type: :request do
  let(:company) { create(:company) }
  let(:manager) { create(:user, :manager, company: company) }
  let(:employee) { create(:user, company: company, manager: manager) }
  let(:leave_type) { create(:leave_type, company: company) }
  let(:headers) { auth_headers(manager) }

  describe "GET /api/v1/team_requests" do
    let!(:pending_leave) do
      create(:leave_application, user: employee, leave_type: leave_type,
             status: :pending, company: company)
    end

    before do
      create(:leave_application, user: employee, leave_type: leave_type,
             status: :approved, company: company)
    end

    it "returns pending requests for approvable users" do
      get "/api/v1/team_requests", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["id"]).to eq(pending_leave.id)
    end

    it "returns 401 without auth" do
      get "/api/v1/team_requests"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/team_requests/:id" do
    let!(:pending_leave) do
      create(:leave_application, user: employee, leave_type: leave_type,
             status: :pending, company: company)
    end

    it "returns the leave application" do
      get "/api/v1/team_requests/#{pending_leave.id}", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(pending_leave.id)
    end

    it "returns 404 for non-existent id" do
      get "/api/v1/team_requests/00000000-0000-0000-0000-000000000000", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 403 when user tries to view own leave" do
      own_leave = create(:leave_application, user: manager, leave_type: leave_type,
                         status: :pending, company: company)
      get "/api/v1/team_requests/#{own_leave.id}", headers: headers
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for cross-company leave" do
      other_company = create(:company)
      other_user = create(:user, company: other_company)
      cross_leave = create(:leave_application, user: other_user,
                            leave_type: create(:leave_type, company: other_company),
                            status: :pending, company: other_company)
      get "/api/v1/team_requests/#{cross_leave.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/team_requests/:id" do
    let!(:pending_leave) do
      create(:leave_application, user: employee, leave_type: leave_type,
             status: :pending, company: company)
    end

    it "approves a leave application" do
      patch "/api/v1/team_requests/#{pending_leave.id}",
            params: { leave: { status: "approved", reviewer_remarks: "OK" } },
            headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("approved")
    end

    it "rejects a leave application" do
      patch "/api/v1/team_requests/#{pending_leave.id}",
            params: { leave: { status: "rejected", reviewer_remarks: "Denied" } },
            headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("rejected")
    end

    it "returns errors for invalid status" do
      patch "/api/v1/team_requests/#{pending_leave.id}",
            params: { leave: { status: "invalid" } },
            headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/team_requests/:id/coverage" do
    let!(:pending_leave) do
      create(:leave_application, user: employee, leave_type: leave_type,
             status: :pending, company: company,
             start_date: Date.current + 1.day, end_date: Date.current + 3.days)
    end
    let!(:colleague) { create(:user, company: company) }
    let!(:colleague_leave) do
      create(:leave_application, user: colleague, leave_type: leave_type,
             status: :approved, company: company,
             start_date: Date.current + 2.day, end_date: Date.current + 2.days)
    end

    it "returns coverage for the leave range" do
      get "/api/v1/team_requests/#{pending_leave.id}/coverage", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["days"]).to be_an(Array)
      expect(json["days"].length).to eq(3)
      expect(json["applicant"]["full_name"]).to eq(employee.full_name)
      expect(json["team_size"]).to be_a(Integer)
    end

    it "shows others_on_leave for days with conflicts" do
      get "/api/v1/team_requests/#{pending_leave.id}/coverage", headers: headers
      json = JSON.parse(response.body)
      day2 = json["days"].find { |d| d["date"] == (Date.current + 2.days).to_s }
      expect(day2["others_on_leave"]).not_to be_empty
      expect(day2["others_on_leave"][0]["full_name"]).to eq(colleague.full_name)
    end

    it "returns 403 for non-approver" do
      other_manager = create(:user, :manager, company: company)
      other_headers = auth_headers(other_manager)
      get "/api/v1/team_requests/#{pending_leave.id}/coverage", headers: other_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for non-existent leave" do
      get "/api/v1/team_requests/00000000-0000-0000-0000-000000000000/coverage", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 403 for cross-company leave" do
      other_company = create(:company)
      other_user = create(:user, company: other_company)
      cross_leave = create(:leave_application, user: other_user,
                            leave_type: create(:leave_type, company: other_company),
                            status: :pending, company: other_company)
      get "/api/v1/team_requests/#{cross_leave.id}/coverage", headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end
end