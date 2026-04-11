class PublicHolidayBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :holiday_date, :year, :is_mandatory, :is_replacement, :company_id
end
