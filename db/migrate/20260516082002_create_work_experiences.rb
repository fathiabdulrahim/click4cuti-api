class CreateWorkExperiences < ActiveRecord::Migration[8.1]
  def change
    create_table :work_experiences, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.string :company_name, null: false
      t.string :position, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :work_experiences, :user_id
    add_foreign_key :work_experiences, :users, column: :user_id
  end
end
