class WorkScheduleBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :start_time, :end_time, :break_start, :break_end, :rest_days, :is_active, :company_id
end
