class LeaveApplicationBlueprint < Blueprinter::Base
  identifier :id
  fields :start_date, :end_date, :total_days, :requires_ceo_approval

  field(:status)     { |app| app.status.to_s.upcase }
  field(:created_at) { |app| app.created_at&.iso8601 }
  field(:updated_at) { |app| app.updated_at&.iso8601 }

  association :leave_type, blueprint: LeaveTypeBlueprint
  association :user,       blueprint: UserBlueprint

  view :detail do
    fields :reason, :extended_reason, :reviewer_remarks

    field(:approver_id)   { |app| app.approver_id }
    field(:approver_type) { |app| app.approver_type }

    field :approver do |app|
      next nil unless app.approver
      {
        id:        app.approver.id,
        full_name: app.approver.full_name,
        email:     app.approver.email,
        type:      app.approver_type
      }
    end

    association :leave_day_details, blueprint: LeaveDayDetailBlueprint
  end
end
