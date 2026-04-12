require "rails_helper"

RSpec.describe "Api::V1::Admin::PublicHolidays", type: :request do
  include_context "admin multi-tenant world"

  let!(:resource_a1) { create(:public_holiday, company: company_a1, holiday_date: "2026-01-01", year: 2026) }
  let!(:resource_a2) { create(:public_holiday, company: company_a2, holiday_date: "2026-02-01", year: 2026) }
  let!(:resource_b1) { create(:public_holiday, company: company_b1, holiday_date: "2026-03-01", year: 2026) }

  let(:base_path) { "/api/v1/admin/public_holidays" }
  let(:path_lambda) { ->(resource) { "#{base_path}/#{resource.id}" } }

  describe "GET /api/v1/admin/public_holidays" do
    it_behaves_like "requires admin authentication", :get, "/api/v1/admin/public_holidays"
    it_behaves_like "admin scoped index", "/api/v1/admin/public_holidays"
  end

  describe "GET /api/v1/admin/public_holidays/:id" do
    it_behaves_like "admin cross-tenant show", ->(r) { "/api/v1/admin/public_holidays/#{r.id}" }

    context "as super_admin" do
      it "returns the public holiday" do
        get path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(resource_a1.id)
      end
    end
  end

  describe "POST /api/v1/admin/public_holidays" do
    let(:valid_params) do
      { public_holiday: { name: "Test Holiday", holiday_date: "2026-12-25", year: 2026, company_id: company_a1.id } }
    end

    context "as super_admin" do
      it "creates a public holiday" do
        post base_path, params: valid_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("Test Holiday")
      end
    end

    context "as company_admin" do
      it "creates a public holiday in own company" do
        post base_path, params: valid_params.to_json, headers: company_a1_headers
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("Test Holiday")
      end
    end
  end

  describe "PATCH /api/v1/admin/public_holidays/:id" do
    let(:update_params) { { public_holiday: { name: "Updated" } } }

    it_behaves_like "admin cross-tenant update",
                    ->(r) { "/api/v1/admin/public_holidays/#{r.id}" },
                    { public_holiday: { name: "Updated" } }

    context "as super_admin" do
      it "updates the public holiday" do
        patch path_lambda.call(resource_a1), params: update_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["name"]).to eq("Updated")
      end
    end
  end

  describe "DELETE /api/v1/admin/public_holidays/:id" do
    it_behaves_like "admin cross-tenant destroy", ->(r) { "/api/v1/admin/public_holidays/#{r.id}" }

    context "as super_admin" do
      it "destroys the public holiday" do
        delete path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
