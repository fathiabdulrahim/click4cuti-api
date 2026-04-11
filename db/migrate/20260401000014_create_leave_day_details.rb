class CreateLeaveDayDetails < ActiveRecord::Migration[8.1]
  def change
    create_table :leave_day_details, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid   :leave_application_id, null: false
      t.date   :leave_date,           null: false
      t.string :day_type,             null: false  # FULL_DAY, HALF_DAY_AM, HALF_DAY_PM
    end

    add_index :leave_day_details, :leave_application_id
    add_index :leave_day_details, [:leave_application_id, :leave_date], unique: true
  end
end
