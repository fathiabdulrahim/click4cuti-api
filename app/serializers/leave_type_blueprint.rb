class LeaveTypeBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :category, :default_days_tier1, :default_days_tier2, :default_days_tier3,
         :max_consecutive_days, :requires_document, :allows_half_day, :allows_carry_forward,
         :max_carry_forward_days, :max_times_per_year, :shared_balance_with, :is_active
end
