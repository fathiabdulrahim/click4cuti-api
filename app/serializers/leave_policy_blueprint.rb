class LeavePolicyBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :description, :advance_notice_days, :is_active, :company_id

  view :detail do
    association :leave_types, blueprint: LeaveTypeBlueprint
  end
end
