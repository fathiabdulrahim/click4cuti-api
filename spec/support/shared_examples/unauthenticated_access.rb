RSpec.shared_examples "requires authentication" do |method, path|
  it "returns 401 when unauthenticated" do
    send(method, path, headers: { "Content-Type" => "application/json" })
    expect(response).to have_http_status(:unauthorized)
  end
end

RSpec.shared_examples "requires admin authentication" do |method, path|
  it "returns 401 when unauthenticated" do
    send(method, path, headers: { "Content-Type" => "application/json" })
    expect(response).to have_http_status(:unauthorized)
  end
end
