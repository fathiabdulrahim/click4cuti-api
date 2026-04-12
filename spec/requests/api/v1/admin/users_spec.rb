require "rails_helper"

RSpec.describe "Api::V1::Admin::Users", type: :request do
  include_context "admin multi-tenant world"

  let(:base_path) { "/api/v1/admin/users" }

  # Users in different companies for scoping tests
  let!(:user_a1) { create(:user, company: company_a1) }
  let!(:user_a2) { create(:user, company: company_a2) }
  let!(:user_b1) { create(:user, company: company_b1) }

  # Leave policy required by Users::OnboardService
  let!(:leave_policy_a1) { create(:leave_policy, company: company_a1, is_active: true) }

  let(:valid_create_params) do
    {
      user: {
        full_name: "Test User",
        email: "new@acme.com",
        company_id: company_a1.id,
        role: "EMPLOYEE",
        join_date: Date.current.to_s,
        gender: "MALE"
      }
    }
  end

  let(:valid_update_params) do
    { user: { full_name: "Updated Name" } }
  end

  # ── Unauthenticated ──────────────────────────────────────────────────

  describe "unauthenticated requests" do
    it "GET index returns 401" do
      get base_path
      expect(response).to have_http_status(:unauthorized)
    end

    it "GET show returns 401" do
      get "#{base_path}/#{user_a1.id}"
      expect(response).to have_http_status(:unauthorized)
    end

    it "POST create returns 401" do
      post base_path, params: valid_create_params.to_json,
                       headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "PATCH update returns 401" do
      patch "#{base_path}/#{user_a1.id}", params: valid_update_params.to_json,
                                           headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "DELETE destroy returns 401" do
      delete "#{base_path}/#{user_a1.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ── Super Admin ──────────────────────────────────────────────────────

  describe "as super_admin" do
    describe "GET /api/v1/admin/users" do
      it "returns all users" do
        get base_path, headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(user_a1.id, user_a2.id, user_b1.id)
      end
    end

    describe "GET /api/v1/admin/users/:id" do
      it "can show any user" do
        get "#{base_path}/#{user_b1.id}", headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(user_b1.id)
      end
    end
  end

  # ── Agency Admin (agency A) ──────────────────────────────────────────

  describe "as agency_admin_a" do
    describe "GET /api/v1/admin/users" do
      it "sees users in agency A companies only" do
        get base_path, headers: agency_a_headers
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(user_a1.id, user_a2.id)
        expect(ids).not_to include(user_b1.id)
      end
    end

    describe "GET /api/v1/admin/users/:id" do
      it "can show a user in their agency" do
        get "#{base_path}/#{user_a1.id}", headers: agency_a_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(user_a1.id)
      end

      it "returns 404 for a user in another agency" do
        get "#{base_path}/#{user_b1.id}", headers: agency_a_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # ── Company Admin (company A1) ───────────────────────────────────────

  describe "as company_admin_a1" do
    describe "GET /api/v1/admin/users" do
      it "sees only users in their own company" do
        get base_path, headers: company_a1_headers
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.map { |r| r["id"] }
        expect(ids).to include(user_a1.id)
        expect(ids).not_to include(user_a2.id, user_b1.id)
      end
    end

    describe "GET /api/v1/admin/users/:id" do
      it "can show a user in their own company" do
        get "#{base_path}/#{user_a1.id}", headers: company_a1_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(user_a1.id)
      end

      it "returns 404 for a user in another company (same agency)" do
        get "#{base_path}/#{user_a2.id}", headers: company_a1_headers
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for a user in another agency" do
        get "#{base_path}/#{user_b1.id}", headers: company_a1_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH /api/v1/admin/users/:id" do
      it "can update a user in their own company" do
        patch "#{base_path}/#{user_a1.id}", params: valid_update_params.to_json,
                                             headers: company_a1_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["full_name"]).to eq("Updated Name")
      end

      it "returns 404 for a user in another company" do
        patch "#{base_path}/#{user_b1.id}", params: valid_update_params.to_json,
                                             headers: company_a1_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /api/v1/admin/users" do
      it "creates a user via OnboardService" do
        expect {
          post base_path, params: valid_create_params.to_json, headers: company_a1_headers
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["full_name"]).to eq("Test User")
      end
    end

    describe "DELETE /api/v1/admin/users/:id" do
      it "soft-deletes the user by setting is_active to false" do
        delete "#{base_path}/#{user_a1.id}", headers: company_a1_headers
        expect(response).to have_http_status(:ok)
        expect(user_a1.reload.is_active).to be(false)
      end

      it "returns 404 for a user in another company" do
        delete "#{base_path}/#{user_b1.id}", headers: company_a1_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
