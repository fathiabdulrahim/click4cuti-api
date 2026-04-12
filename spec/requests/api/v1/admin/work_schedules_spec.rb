require "rails_helper"

RSpec.describe "Api::V1::Admin::WorkSchedules", type: :request do
  include_context "admin multi-tenant world"

  let!(:resource_a1) { create(:work_schedule, company: company_a1) }
  let!(:resource_a2) { create(:work_schedule, company: company_a2) }
  let!(:resource_b1) { create(:work_schedule, company: company_b1) }

  let(:base_path) { "/api/v1/admin/work_schedules" }
  let(:path_lambda) { ->(resource) { "#{base_path}/#{resource.id}" } }

  describe "GET /api/v1/admin/work_schedules" do
    it_behaves_like "requires admin authentication", :get, "/api/v1/admin/work_schedules"
    it_behaves_like "admin scoped index", "/api/v1/admin/work_schedules"
  end

  describe "GET /api/v1/admin/work_schedules/:id" do
    it_behaves_like "admin cross-tenant show", ->(r) { "/api/v1/admin/work_schedules/#{r.id}" }

    context "as super_admin" do
      it "returns the work schedule" do
        get path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(resource_a1.id)
      end
    end
  end

  describe "POST /api/v1/admin/work_schedules" do
    let(:valid_params) do
      { work_schedule: { name: "Flex", start_time: "08:00", end_time: "17:00", rest_days: "SUNDAY", company_id: company_a1.id } }
    end

    context "as super_admin" do
      it "creates a work schedule" do
        post base_path, params: valid_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("Flex")
      end
    end

    context "as company_admin" do
      it "creates a work schedule in own company" do
        post base_path, params: valid_params.to_json, headers: company_a1_headers
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("Flex")
      end
    end
  end

  describe "PATCH /api/v1/admin/work_schedules/:id" do
    let(:update_params) { { work_schedule: { name: "Updated" } } }

    it_behaves_like "admin cross-tenant update",
                    ->(r) { "/api/v1/admin/work_schedules/#{r.id}" },
                    { work_schedule: { name: "Updated" } }

    context "as super_admin" do
      it "updates the work schedule" do
        patch path_lambda.call(resource_a1), params: update_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["name"]).to eq("Updated")
      end
    end
  end

  describe "DELETE /api/v1/admin/work_schedules/:id" do
    it_behaves_like "admin cross-tenant destroy", ->(r) { "/api/v1/admin/work_schedules/#{r.id}" }

    context "as super_admin" do
      it "deactivates the work schedule" do
        delete path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to eq("Work schedule deactivated.")
      end
    end
  end
end
