require "rails_helper"

RSpec.describe "Api::V1::Leaves", type: :request do
  let!(:company_a) { create(:company) }
  let!(:company_b) { create(:company) }
  let!(:leave_policy_a) { create(:leave_policy, company: company_a) }
  let!(:leave_type_a) { create(:leave_type, leave_policy: leave_policy_a) }

  # Company A users
  let!(:employee_a) { create(:user, :employee, company: company_a) }
  let!(:manager_a) { create(:user, :manager, company: company_a) }
  let!(:admin_user_a) { create(:user, :admin, company: company_a) }

  # Company B user
  let!(:employee_b) { create(:user, :employee, company: company_b) }

  # Set manager relationship
  before { employee_a.update!(manager: manager_a) }

  # Leave applications
  let!(:leave_a) do
    create(:leave_application, user: employee_a, leave_type: leave_type_a)
  end
  let!(:leave_manager_a) do
    create(:leave_application, user: manager_a, leave_type: leave_type_a)
  end

  let!(:leave_policy_b) { create(:leave_policy, company: company_b) }
  let!(:leave_type_b) { create(:leave_type, leave_policy: leave_policy_b, name: "Annual Leave B") }
  let!(:leave_b) do
    create(:leave_application, user: employee_b, leave_type: leave_type_b)
  end

  let(:employee_a_headers) { auth_headers_for_user(employee_a) }
  let(:manager_a_headers) { auth_headers_for_user(manager_a) }
  let(:admin_a_headers) { auth_headers_for_user(admin_user_a) }
  let(:employee_b_headers) { auth_headers_for_user(employee_b) }

  describe "GET /api/v1/leaves" do
    it_behaves_like "requires authentication", :get, "/api/v1/leaves"

    context "as employee" do
      it "sees only own leave applications" do
        get "/api/v1/leaves", headers: employee_a_headers
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(leave_a.id)
        expect(ids).not_to include(leave_manager_a.id, leave_b.id)
      end
    end

    context "as manager" do
      it "sees own and subordinates' leave applications" do
        get "/api/v1/leaves", headers: manager_a_headers
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(leave_a.id, leave_manager_a.id)
        expect(ids).not_to include(leave_b.id)
      end
    end

    context "as admin (user role)" do
      it "sees all company leave applications" do
        get "/api/v1/leaves", headers: admin_a_headers
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(leave_a.id, leave_manager_a.id)
        expect(ids).not_to include(leave_b.id)
      end
    end

    context "cross-company isolation" do
      it "employee from company B cannot see company A leaves" do
        get "/api/v1/leaves", headers: employee_b_headers
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(leave_b.id)
        expect(ids).not_to include(leave_a.id, leave_manager_a.id)
      end
    end
  end

  describe "GET /api/v1/leaves/:id" do
    it "employee can view own leave" do
      get "/api/v1/leaves/#{leave_a.id}", headers: employee_a_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(leave_a.id)
    end

    it "employee cannot view another employee's leave (404 via policy_scope)" do
      get "/api/v1/leaves/#{leave_manager_a.id}", headers: employee_a_headers
      expect(response).to have_http_status(:not_found)
    end

    it "employee cannot view cross-company leave" do
      get "/api/v1/leaves/#{leave_b.id}", headers: employee_a_headers
      expect(response).to have_http_status(:not_found)
    end

    it "manager can view subordinate's leave" do
      get "/api/v1/leaves/#{leave_a.id}", headers: manager_a_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # ── Manager sees ONLY managed employees, not unmanaged ────────────────

  describe "manager subordinate scoping" do
    let!(:unmanaged_employee) { create(:user, :employee, company: company_a) } # no manager set
    let!(:leave_unmanaged) do
      create(:leave_application, user: unmanaged_employee, leave_type: leave_type_a)
    end

    it "manager cannot see leaves from employees they don't manage" do
      get "/api/v1/leaves", headers: manager_a_headers
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(leave_a.id)          # managed subordinate
      expect(ids).to include(leave_manager_a.id)   # own leave
      expect(ids).not_to include(leave_unmanaged.id) # NOT managed
    end

    it "manager cannot show a leave from an unmanaged employee" do
      get "/api/v1/leaves/#{leave_unmanaged.id}", headers: manager_a_headers
      expect(response).to have_http_status(:not_found)
    end

    it "admin (user role) CAN see the unmanaged employee's leave" do
      get "/api/v1/leaves", headers: admin_a_headers
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(leave_unmanaged.id)
    end
  end

  describe "DELETE /api/v1/leaves/:id" do
    it "owner can cancel own pending leave" do
      delete "/api/v1/leaves/#{leave_a.id}", headers: employee_a_headers
      expect(response).to have_http_status(:ok)
      expect(leave_a.reload.status).to eq("cancelled")
    end

    it "other employee cannot cancel someone else's leave" do
      delete "/api/v1/leaves/#{leave_a.id}", headers: employee_b_headers
      expect(response).to have_http_status(:not_found).or have_http_status(:forbidden)
    end

    it "cannot cancel a non-pending leave" do
      leave_a.update!(status: "APPROVED")
      delete "/api/v1/leaves/#{leave_a.id}", headers: employee_a_headers
      expect(response).to have_http_status(:forbidden)
    end
  end
end
