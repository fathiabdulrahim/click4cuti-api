class WarningLetterBlueprint < Blueprinter::Base
  identifier :id
  fields :reason, :year, :issued_date, :acknowledged, :acknowledged_at,
         :source, :details, :action_taken, :issued_by_id, :issued_by_type,
         :company_id, :user_id

  association :user,       blueprint: UserBlueprint
  association :leave_type, blueprint: LeaveTypeBlueprint

  field :supporting_document_url do |w, _opts|
    next nil unless w.supporting_document.attached?
    Rails.application.routes.url_helpers.rails_blob_url(w.supporting_document, host: ENV.fetch("API_HOST", "localhost:3000"))
  rescue StandardError
    nil
  end

  view :detail do
    fields :created_at
  end
end
