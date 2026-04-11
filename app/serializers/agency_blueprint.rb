class AgencyBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :email, :phone, :is_active

  view :detail do
    fields :address, :created_at, :updated_at
  end
end
