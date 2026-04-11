class CreateUserWorkSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :user_work_schedules, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id,          null: false
      t.uuid :work_schedule_id, null: false
      t.date :effective_from,   null: false
      t.date :effective_to
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :user_work_schedules, [:user_id, :work_schedule_id]
    add_index :user_work_schedules, :work_schedule_id
  end
end
