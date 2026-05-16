class CareerProgressBlueprint < Blueprinter::Base
  identifier :id

  fields :user_id, :company_id, :job_title, :effective_date,
         :manager_id, :department_id, :job_type, :description

  view :detail do
    fields :created_at, :updated_at
  end
end
