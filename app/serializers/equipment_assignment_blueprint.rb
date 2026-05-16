class EquipmentAssignmentBlueprint < Blueprinter::Base
  identifier :id

  fields :user_id, :equipment_type, :equipment_details, :date_received, :date_return

  field :supporting_document_url do |e, _opts|
    next nil unless e.supporting_document.attached?
    Rails.application.routes.url_helpers.rails_blob_url(e.supporting_document, host: ENV.fetch("API_HOST", "localhost:3000"))
  rescue StandardError
    nil
  end

  field :is_returned do |e, _opts|
    e.date_return.present?
  end

  view :detail do
    fields :created_at, :updated_at
  end
end
