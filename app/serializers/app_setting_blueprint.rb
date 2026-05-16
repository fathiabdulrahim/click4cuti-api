class AppSettingBlueprint < Blueprinter::Base
  fields :notifications_enabled, :clock_in_selfie_enabled,
         :early_late_indicator_enabled, :attendance_confirmation_enabled
end
