class WarningLetterBlueprint < Blueprinter::Base
  identifier :id
  fields :reason, :year, :issued_date, :acknowledged, :acknowledged_at, :company_id, :user_id

  association :user,       blueprint: UserBlueprint
  association :leave_type, blueprint: LeaveTypeBlueprint

  view :detail do
    fields :created_at
  end
end
