class CreateWorkSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :work_schedules, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :company_id,  null: false
      t.string  :name,        null: false
      t.time    :start_time,  null: false
      t.time    :end_time,    null: false
      t.time    :break_start
      t.time    :break_end
      t.string  :rest_days,   null: false  # e.g. "Sat,Sun"
      t.boolean :is_active,   null: false, default: true
      t.timestamps
    end

    add_index :work_schedules, :company_id
  end
end
