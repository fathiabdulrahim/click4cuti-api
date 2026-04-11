class CompanyBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :registration_number, :hr_email, :state, :is_active, :agency_id

  view :detail do
    fields :address, :created_at, :updated_at
  end
end
