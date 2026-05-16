class CreateTrainings < ActiveRecord::Migration[8.1]
  def change
    create_table :trainings, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.string :title, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.text :description, null: false
      t.date :received_date, null: false
      t.date :expired_date, null: false
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :trainings, :user_id
    add_index :trainings, [:user_id, :expired_date]
    add_foreign_key :trainings, :users, column: :user_id
  end
end
