class CreateEquipmentAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :equipment_assignments, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.string :equipment_type, null: false
      t.text :equipment_details, null: false
      t.date :date_received, null: false
      t.date :date_return
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :equipment_assignments, :user_id
    add_foreign_key :equipment_assignments, :users, column: :user_id
  end
end
