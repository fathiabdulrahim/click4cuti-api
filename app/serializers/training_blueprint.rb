class TrainingBlueprint < Blueprinter::Base
  identifier :id

  fields :user_id, :title, :start_date, :end_date, :description,
         :received_date, :expired_date

  field :certification_url do |t, _opts|
    next nil unless t.certification.attached?
    Rails.application.routes.url_helpers.rails_blob_url(t.certification, host: ENV.fetch("API_HOST", "localhost:3000"))
  rescue StandardError
    nil
  end

  field :is_expired do |t, _opts|
    t.expired_date.present? && t.expired_date < Date.current
  end

  view :detail do
    fields :created_at, :updated_at
  end
end
