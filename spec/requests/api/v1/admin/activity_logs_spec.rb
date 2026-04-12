require "rails_helper"

RSpec.describe "Api::V1::Admin::ActivityLogs", type: :request do
  include_context "admin multi-tenant world"

  let!(:resource_a1) { create(:activity_log, company: company_a1) }
  let!(:resource_a2) { create(:activity_log, company: company_a2) }
  let!(:resource_b1) { create(:activity_log, company: company_b1) }

  let(:base_path) { "/api/v1/admin/activity_logs" }

  describe "GET /api/v1/admin/activity_logs" do
    it_behaves_like "requires admin authentication", :get, "/api/v1/admin/activity_logs"
    it_behaves_like "admin scoped index", "/api/v1/admin/activity_logs"
  end
end
