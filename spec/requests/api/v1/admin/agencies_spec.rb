require "rails_helper"

RSpec.describe "Api::V1::Admin::Agencies", type: :request do
  include_context "admin multi-tenant world"

  let(:base_path) { "/api/v1/admin/agencies" }

  let(:valid_create_params) do
    { agency: { name: "Test Agency", email: "test@agency.com", phone: "123" } }
  end

  let(:valid_update_params) do
    { agency: { name: "Updated Agency" } }
  end

  # ── Unauthenticated ──────────────────────────────────────────────────

  describe "unauthenticated requests" do
    it "GET index returns 401" do
      get base_path
      expect(response).to have_http_status(:unauthorized)
    end

    it "GET show returns 401" do
      get "#{base_path}/#{agency_a.id}"
      expect(response).to have_http_status(:unauthorized)
    end

    it "POST create returns 401" do
      post base_path, params: valid_create_params.to_json,
                       headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "PATCH update returns 401" do
      patch "#{base_path}/#{agency_a.id}", params: valid_update_params.to_json,
                                            headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "DELETE destroy returns 401" do
      delete "#{base_path}/#{agency_a.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ── Super Admin ──────────────────────────────────────────────────────

  describe "as super_admin" do
    describe "GET /api/v1/admin/agencies" do
      it "returns all agencies" do
        get base_path, headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(agency_a.id, agency_b.id)
      end
    end

    describe "GET /api/v1/admin/agencies/:id" do
      it "returns the agency" do
        get "#{base_path}/#{agency_a.id}", headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(agency_a.id)
      end
    end

    describe "POST /api/v1/admin/agencies" do
      it "creates an agency" do
        expect {
          post base_path, params: valid_create_params.to_json, headers: super_admin_headers
        }.to change(HrAgency, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("Test Agency")
      end
    end

    describe "PATCH /api/v1/admin/agencies/:id" do
      it "updates the agency" do
        patch "#{base_path}/#{agency_a.id}", params: valid_update_params.to_json,
                                              headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["name"]).to eq("Updated Agency")
      end
    end

    describe "DELETE /api/v1/admin/agencies/:id" do
      it "soft-deletes the agency by setting is_active to false" do
        delete "#{base_path}/#{agency_a.id}", headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(agency_a.reload.is_active).to be(false)
      end
    end
  end

  # ── Agency Admin ─────────────────────────────────────────────────────

  describe "as agency_admin" do
    describe "GET /api/v1/admin/agencies" do
      it "returns empty array (scope.none)" do
        get base_path, headers: agency_a_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to be_empty
      end
    end

    describe "GET /api/v1/admin/agencies/:id" do
      it "returns 403 for any agency" do
        get "#{base_path}/#{agency_a.id}", headers: agency_a_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST /api/v1/admin/agencies" do
      it "returns 403" do
        post base_path, params: valid_create_params.to_json, headers: agency_a_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "PATCH /api/v1/admin/agencies/:id" do
      it "returns 403" do
        patch "#{base_path}/#{agency_a.id}", params: valid_update_params.to_json,
                                              headers: agency_a_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "DELETE /api/v1/admin/agencies/:id" do
      it "returns 403" do
        delete "#{base_path}/#{agency_a.id}", headers: agency_a_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ── Company Admin ────────────────────────────────────────────────────

  describe "as company_admin" do
    describe "GET /api/v1/admin/agencies" do
      it "returns empty array (scope.none)" do
        get base_path, headers: company_a1_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to be_empty
      end
    end

    describe "GET /api/v1/admin/agencies/:id" do
      it "returns 403 for any agency" do
        get "#{base_path}/#{agency_a.id}", headers: company_a1_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST /api/v1/admin/agencies" do
      it "returns 403" do
        post base_path, params: valid_create_params.to_json, headers: company_a1_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "PATCH /api/v1/admin/agencies/:id" do
      it "returns 403" do
        patch "#{base_path}/#{agency_a.id}", params: valid_update_params.to_json,
                                              headers: company_a1_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "DELETE /api/v1/admin/agencies/:id" do
      it "returns 403" do
        delete "#{base_path}/#{agency_a.id}", headers: company_a1_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
