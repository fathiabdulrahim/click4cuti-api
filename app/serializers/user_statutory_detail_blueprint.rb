class UserStatutoryDetailBlueprint < Blueprinter::Base
  identifier :id
  fields :user_id, :epf_number, :epf_contribution_start,
         :socso_number, :socso_contribution_start_age,
         :eis_employee_rate, :eis_employer_rate,
         :income_tax_number, :vola_amount
end
