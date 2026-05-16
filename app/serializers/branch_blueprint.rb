class BranchBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :address, :state, :is_active, :company_id

  view :detail do
    fields :created_at, :updated_at
  end
end
