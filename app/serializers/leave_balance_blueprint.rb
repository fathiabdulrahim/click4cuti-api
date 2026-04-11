class LeaveBalanceBlueprint < Blueprinter::Base
  identifier :id
  fields :year, :total_entitled, :carried_forward, :used_days, :pending_days, :remaining_days

  association :leave_type, blueprint: LeaveTypeBlueprint
end
