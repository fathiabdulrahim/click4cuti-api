require "rails_helper"

RSpec.describe "Api::V1::Admin::WarningLetters", type: :request do
  include_context "admin multi-tenant world"

  let!(:user_a1) { create(:user, company: company_a1) }
  let!(:user_a2) { create(:user, company: company_a2) }
  let!(:user_b1) { create(:user, company: company_b1) }

  let!(:leave_type_a1) { create(:leave_type, leave_policy: create(:leave_policy, company: company_a1)) }
  let!(:leave_type_a2) { create(:leave_type, leave_policy: create(:leave_policy, company: company_a2)) }
  let!(:leave_type_b1) { create(:leave_type, leave_policy: create(:leave_policy, company: company_b1)) }

  let!(:resource_a1) { create(:warning_letter, user: user_a1, company: company_a1, leave_type: leave_type_a1) }
  let!(:resource_a2) { create(:warning_letter, user: user_a2, company: company_a2, leave_type: leave_type_a2) }
  let!(:resource_b1) { create(:warning_letter, user: user_b1, company: company_b1, leave_type: leave_type_b1) }

  let(:base_path) { "/api/v1/admin/warning_letters" }
  let(:path_lambda) { ->(resource) { "#{base_path}/#{resource.id}" } }

  describe "GET /api/v1/admin/warning_letters" do
    it_behaves_like "requires admin authentication", :get, "/api/v1/admin/warning_letters"
    it_behaves_like "admin scoped index", "/api/v1/admin/warning_letters"
  end

  describe "GET /api/v1/admin/warning_letters/:id" do
    it_behaves_like "admin cross-tenant show", ->(r) { "/api/v1/admin/warning_letters/#{r.id}" }

    context "as super_admin" do
      it "returns the warning letter" do
        get path_lambda.call(resource_a1), headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(resource_a1.id)
      end
    end
  end

  describe "PATCH /api/v1/admin/warning_letters/:id" do
    let(:update_params) { { warning_letter: { acknowledged: true } } }

    it_behaves_like "admin cross-tenant update",
                    ->(r) { "/api/v1/admin/warning_letters/#{r.id}" },
                    { warning_letter: { acknowledged: true } }

    context "as super_admin" do
      it "acknowledges the warning letter" do
        patch path_lambda.call(resource_a1), params: update_params.to_json, headers: super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(resource_a1.reload.acknowledged).to be true
      end
    end

    context "as company_admin" do
      it "acknowledges a warning letter in own company" do
        patch path_lambda.call(resource_a1), params: update_params.to_json, headers: company_a1_headers
        expect(response).to have_http_status(:ok)
        expect(resource_a1.reload.acknowledged).to be true
      end
    end
  end
end
