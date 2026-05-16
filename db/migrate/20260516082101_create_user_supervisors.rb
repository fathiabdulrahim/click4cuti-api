class CreateUserSupervisors < ActiveRecord::Migration[8.1]
  def change
    create_table :user_supervisors, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id,       null: false
      t.uuid :supervisor_id, null: false
      t.string :category,    null: false
      t.integer :level,      null: false
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :user_supervisors, [:user_id, :category, :level], unique: true, name: "idx_user_supervisors_unique"
    add_index :user_supervisors, :supervisor_id
    add_foreign_key :user_supervisors, :users, column: :user_id
    add_foreign_key :user_supervisors, :users, column: :supervisor_id

    execute <<~SQL
      ALTER TABLE user_supervisors
      ADD CONSTRAINT user_supervisors_no_self_assignment
      CHECK (user_id <> supervisor_id)
    SQL

    execute <<~SQL
      ALTER TABLE user_supervisors
      ADD CONSTRAINT user_supervisors_category_check
      CHECK (category IN ('LEAVE', 'CLAIM', 'OVERTIME', 'TIMEOFF'))
    SQL

    execute <<~SQL
      ALTER TABLE user_supervisors
      ADD CONSTRAINT user_supervisors_level_check
      CHECK (level IN (1, 2))
    SQL
  end
end
