class ClaimTypeBlueprint < Blueprinter::Base
  identifier :id
  fields :company_id, :name, :code, :description,
         :default_application_limit, :default_annual_limit,
         :requires_document, :is_active

  view :detail do
    fields :created_at, :updated_at
  end
end
