class CreateLeaveBalances < ActiveRecord::Migration[8.1]
  def change
    create_table :leave_balances, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :user_id,        null: false
      t.uuid    :leave_type_id,  null: false
      t.integer :year,           null: false
      t.decimal :total_entitled, null: false, precision: 8, scale: 2, default: "0.0"
      t.decimal :carried_forward, null: false, precision: 8, scale: 2, default: "0.0"
      t.decimal :used_days,      null: false, precision: 8, scale: 2, default: "0.0"
      t.decimal :pending_days,   null: false, precision: 8, scale: 2, default: "0.0"
      t.decimal :remaining_days, null: false, precision: 8, scale: 2, default: "0.0"
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :leave_balances, [:user_id, :leave_type_id, :year], unique: true
    add_index :leave_balances, :leave_type_id
  end
end
