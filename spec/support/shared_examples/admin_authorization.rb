# Shared context for multi-tenant admin test world
RSpec.shared_context "admin multi-tenant world" do
  let!(:agency_a) { create(:hr_agency) }
  let!(:agency_b) { create(:hr_agency) }
  let!(:company_a1) { create(:company, hr_agency: agency_a) }
  let!(:company_a2) { create(:company, hr_agency: agency_a) }
  let!(:company_b1) { create(:company, hr_agency: agency_b) }

  let!(:super_admin) { create(:admin_user, :super_admin) }
  let!(:agency_admin_a) { create(:admin_user, :agency, hr_agency: agency_a) }
  let!(:agency_admin_b) { create(:admin_user, :agency, hr_agency: agency_b) }
  let!(:company_admin_a1) { create(:admin_user, :company, company: company_a1) }
  let!(:company_admin_b1) { create(:admin_user, :company, company: company_b1) }

  let(:super_admin_headers) { auth_headers_for_admin(super_admin) }
  let(:agency_a_headers) { auth_headers_for_admin(agency_admin_a) }
  let(:agency_b_headers) { auth_headers_for_admin(agency_admin_b) }
  let(:company_a1_headers) { auth_headers_for_admin(company_admin_a1) }
  let(:company_b1_headers) { auth_headers_for_admin(company_admin_b1) }
end

# Tests that an admin index endpoint properly scopes data by tenant
# Requires: resource_a1, resource_a2, resource_b1 to be defined as let! in the calling spec
RSpec.shared_examples "admin scoped index" do |path|
  context "as super_admin" do
    it "sees all records" do
      get path, headers: super_admin_headers
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(resource_a1.id, resource_a2.id, resource_b1.id)
    end
  end

  context "as agency_admin (agency A)" do
    it "sees only records from their agency's companies" do
      get path, headers: agency_a_headers
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(resource_a1.id, resource_a2.id)
      expect(ids).not_to include(resource_b1.id)
    end
  end

  context "as company_admin (company A1)" do
    it "sees only records from their own company" do
      get path, headers: company_a1_headers
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(resource_a1.id)
      expect(ids).not_to include(resource_a2.id, resource_b1.id)
    end
  end
end

# Tests that cross-tenant show returns 404
RSpec.shared_examples "admin cross-tenant show" do |path_lambda|
  context "as company_admin accessing another company's record" do
    it "returns 404" do
      get path_lambda.call(resource_b1), headers: company_a1_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  context "as agency_admin accessing another agency's record" do
    it "returns 404" do
      get path_lambda.call(resource_b1), headers: agency_a_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end

# Tests that cross-tenant update returns 404
RSpec.shared_examples "admin cross-tenant update" do |path_lambda, valid_params|
  context "as company_admin updating another company's record" do
    it "returns 404" do
      patch path_lambda.call(resource_b1), params: valid_params.to_json, headers: company_a1_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  context "as agency_admin updating another agency's record" do
    it "returns 404" do
      patch path_lambda.call(resource_b1), params: valid_params.to_json, headers: agency_a_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end

# Tests that cross-tenant destroy returns 404
RSpec.shared_examples "admin cross-tenant destroy" do |path_lambda|
  context "as company_admin destroying another company's record" do
    it "returns 404" do
      delete path_lambda.call(resource_b1), headers: company_a1_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  context "as agency_admin destroying another agency's record" do
    it "returns 404" do
      delete path_lambda.call(resource_b1), headers: agency_a_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
