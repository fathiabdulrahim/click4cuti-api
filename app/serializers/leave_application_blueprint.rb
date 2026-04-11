class LeaveApplicationBlueprint < Blueprinter::Base
  identifier :id
  fields :status, :start_date, :end_date, :total_days, :requires_ceo_approval, :created_at, :updated_at

  association :leave_type, blueprint: LeaveTypeBlueprint
  association :user,       blueprint: UserBlueprint

  view :detail do
    fields :reason, :extended_reason, :reviewer_remarks, :approved_by

    association :approver, blueprint: UserBlueprint do |app, _opts|
      app.approver
    end

    association :leave_day_details, blueprint: LeaveDayDetailBlueprint
  end
end
