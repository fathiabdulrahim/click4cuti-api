class CreateCareerProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :career_progresses, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.uuid :company_id, null: false
      t.string :job_title, null: false
      t.date :effective_date, null: false
      t.uuid :manager_id
      t.uuid :department_id
      t.string :job_type
      t.text :description
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :career_progresses, :user_id
    add_index :career_progresses, :company_id
    add_index :career_progresses, [:user_id, :effective_date]
    add_foreign_key :career_progresses, :users, column: :user_id
    add_foreign_key :career_progresses, :companies, column: :company_id
    add_foreign_key :career_progresses, :users, column: :manager_id
    add_foreign_key :career_progresses, :departments, column: :department_id
  end
end
