class UserDocumentBlueprint < Blueprinter::Base
  identifier :id

  fields :user_id, :remarks

  field :file_url do |doc, _opts|
    next nil unless doc.file.attached?
    Rails.application.routes.url_helpers.rails_blob_url(doc.file, host: ENV.fetch("API_HOST", "localhost:3000"))
  rescue StandardError
    nil
  end

  field :file_name do |doc, _opts|
    doc.file.attached? ? doc.file.filename.to_s : nil
  end

  view :detail do
    fields :created_at, :updated_at
  end
end
