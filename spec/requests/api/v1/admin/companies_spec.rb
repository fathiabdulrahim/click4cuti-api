require "rails_helper"

RSpec.describe "Api::V1::Admin::Companies", type: :request do
  include_context "admin multi-tenant world"

  let(:base_path) { "/api/v1/admin/companies" }

  let(:valid_create_params) do
    {
      company: {
        name: "New Co",
        hr_email: "hr@co.com",
        registration_number: "REG001",
        state: "Selangor",
        agency_id: agency_a.id
      }
    }
  end

  let(:valid_update_params) do
    { company: { name: "Updated Co" } }
  end

  # ── Unauthenticated ──────────────────────────────────────────────────

  describe "unauthenticated requests" do
    it "GET index returns 401" do
      get base_path
      expect(response).to have_http_status(:unauthorized)
    end

    it "GET show returns 401" do
      get "#{base_path}/#{company_a1.id}"
      expect(response).to have_http_status(:unauthorized)
    end

    it "POST create returns 401" do
      post base_path, params: valid_create_params.to_json,
                       headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "PATCH update returns 401" do
      patch "#{base_path}/#{company_a1.id}", params: valid_update_params.to_json,
                                              headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "DELETE destroy returns 401" do
      delete "#{base_path}/#{company_a1.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ── Super Admin ──────────────────────────────────────────────────────

  describe "as super_admin" do
    describe "GET /api/v1/admin/companies" do
      it "returns all companies" do
        get base_path, headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(company_a1.id, company_a2.id, company_b1.id)
      end
    end

    describe "GET /api/v1/admin/companies/:id" do
      it "returns the company" do
        get "#{base_path}/#{company_a1.id}", headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(company_a1.id)
      end
    end

    describe "POST /api/v1/admin/companies" do
      it "creates a company via OnboardService" do
        expect {
          post base_path, params: valid_create_params.to_json, headers: super_admin_headers
        }.to change(Company, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("New Co")
      end
    end

    describe "PATCH /api/v1/admin/companies/:id" do
      it "updates the company" do
        patch "#{base_path}/#{company_a1.id}", params: valid_update_params.to_json,
                                                headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["name"]).to eq("Updated Co")
      end
    end

    describe "DELETE /api/v1/admin/companies/:id" do
      it "soft-deletes the company by setting is_active to false" do
        delete "#{base_path}/#{company_a1.id}", headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(company_a1.reload.is_active).to be(false)
      end
    end
  end

  # ── Agency Admin (agency A) ──────────────────────────────────────────

  describe "as agency_admin_a" do
    describe "GET /api/v1/admin/companies" do
      it "sees only companies from their agency" do
        get base_path, headers: agency_a_headers
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(company_a1.id, company_a2.id)
        expect(ids).not_to include(company_b1.id)
      end
    end

    describe "GET /api/v1/admin/companies/:id" do
      it "can show a company in their agency" do
        get "#{base_path}/#{company_a1.id}", headers: agency_a_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(company_a1.id)
      end

      it "returns 404 for a company in another agency" do
        get "#{base_path}/#{company_b1.id}", headers: agency_a_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /api/v1/admin/companies" do
      it "creates a company under their agency" do
        expect {
          post base_path, params: valid_create_params.to_json, headers: agency_a_headers
        }.to change(Company, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    describe "PATCH /api/v1/admin/companies/:id" do
      it "can update a company in their agency" do
        patch "#{base_path}/#{company_a1.id}", params: valid_update_params.to_json,
                                                headers: agency_a_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["name"]).to eq("Updated Co")
      end

      it "returns 404 for a company in another agency" do
        patch "#{base_path}/#{company_b1.id}", params: valid_update_params.to_json,
                                                headers: agency_a_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "DELETE /api/v1/admin/companies/:id" do
      it "returns 403" do
        delete "#{base_path}/#{company_a1.id}", headers: agency_a_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ── Agency Admin vs No-Agency Companies ───────────────────────────────

  describe "agency admin cannot see companies without an agency" do
    let!(:independent_company) { create(:company, hr_agency: nil) }

    it "agency_admin_a does not see the independent (no-agency) company" do
      get base_path, headers: agency_a_headers
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).not_to include(independent_company.id)
    end

    it "agency_admin_a gets 404 when trying to show the independent company" do
      get "#{base_path}/#{independent_company.id}", headers: agency_a_headers
      expect(response).to have_http_status(:not_found)
    end

    it "super_admin CAN see the independent company" do
      get base_path, headers: super_admin_headers
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(independent_company.id)
    end
  end

  # ── Company Admin (company A1) ───────────────────────────────────────

  describe "as company_admin_a1" do
    describe "GET /api/v1/admin/companies" do
      it "sees only their own company" do
        get base_path, headers: company_a1_headers
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(company_a1.id)
        expect(ids).not_to include(company_a2.id, company_b1.id)
      end
    end

    describe "GET /api/v1/admin/companies/:id" do
      it "can show their own company" do
        get "#{base_path}/#{company_a1.id}", headers: company_a1_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(company_a1.id)
      end

      it "returns 404 for another company in the same agency" do
        get "#{base_path}/#{company_a2.id}", headers: company_a1_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /api/v1/admin/companies" do
      it "returns 403" do
        post base_path, params: valid_create_params.to_json, headers: company_a1_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "PATCH /api/v1/admin/companies/:id" do
      it "can update their own company" do
        patch "#{base_path}/#{company_a1.id}", params: valid_update_params.to_json,
                                                headers: company_a1_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["name"]).to eq("Updated Co")
      end

      it "returns 404 for another company" do
        patch "#{base_path}/#{company_a2.id}", params: valid_update_params.to_json,
                                                headers: company_a1_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "DELETE /api/v1/admin/companies/:id" do
      it "returns 403" do
        delete "#{base_path}/#{company_a1.id}", headers: company_a1_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
