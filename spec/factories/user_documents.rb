FactoryBot.define do
  factory :user_document do
    association :user
    remarks { "Sample document" }

    after(:build) do |doc|
      doc.file.attach(
        io: StringIO.new("dummy content"),
        filename: "sample.pdf",
        content_type: "application/pdf"
      )
    end
  end
end
