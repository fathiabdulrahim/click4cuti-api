class DepartmentBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :company_id, :is_active
end
