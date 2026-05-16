class AddAppSettingsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :notifications_enabled,           :boolean, null: false, default: true
    add_column :users, :clock_in_selfie_enabled,         :boolean, null: false, default: false
    add_column :users, :early_late_indicator_enabled,    :boolean, null: false, default: false
    add_column :users, :attendance_confirmation_enabled, :boolean, null: false, default: false
  end
end
