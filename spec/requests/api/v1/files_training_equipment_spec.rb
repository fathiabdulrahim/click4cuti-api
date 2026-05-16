require "rails_helper"

RSpec.describe "Api::V1 Files / Training / Equipment", type: :request do
  let!(:company) { create(:company) }
  let!(:user)    { create(:user, :employee, company: company) }
  let(:headers)  { auth_headers_for_user(user) }

  describe "UserDocuments" do
    it_behaves_like "requires authentication", :get, "/api/v1/user_documents"

    it "creates a document with file upload" do
      file = Rack::Test::UploadedFile.new(StringIO.new("hello"), "text/plain", original_filename: "hello.txt")
      expect {
        post "/api/v1/user_documents",
             params: { remarks: "Offer letter", file: file },
             headers: headers.except("Content-Type")
      }.to change(UserDocument, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(UserDocument.last.file).to be_attached
    end

    it "lists own documents" do
      create(:user_document, user: user)
      get "/api/v1/user_documents", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(1)
    end
  end

  describe "Trainings" do
    it_behaves_like "requires authentication", :get, "/api/v1/trainings"

    it "creates a training record" do
      expect {
        post "/api/v1/trainings",
             params: {
               title: "AWS Cert",
               start_date: "2025-01-01",
               end_date: "2025-01-05",
               description: "AWS Solutions Architect",
               received_date: "2025-01-10",
               expired_date: "2028-01-10"
             }.to_json,
             headers: headers
      }.to change(Training, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe "EquipmentAssignments" do
    it_behaves_like "requires authentication", :get, "/api/v1/equipment_assignments"

    it "records an equipment assignment" do
      expect {
        post "/api/v1/equipment_assignments",
             params: {
               equipment_type: "Laptop",
               equipment_details: "MacBook Pro 14",
               date_received: "2024-06-01"
             }.to_json,
             headers: headers
      }.to change(EquipmentAssignment, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end
end
