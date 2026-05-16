class CreateClaimBalances < ActiveRecord::Migration[8.1]
  def change
    create_table :claim_balances, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.uuid :claim_type_id, null: false
      t.integer :year, null: false
      t.decimal :annual_limit,  precision: 12, scale: 2, null: false, default: 0
      t.decimal :pending_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :used_amount,    precision: 12, scale: 2, null: false, default: 0
      t.decimal :remaining_amount, precision: 12, scale: 2, null: false, default: 0
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :claim_balances, [:user_id, :claim_type_id, :year], unique: true,
              name: "index_claim_balances_on_user_type_year"
    add_index :claim_balances, :claim_type_id
    add_foreign_key :claim_balances, :users, column: :user_id
    add_foreign_key :claim_balances, :claim_types, column: :claim_type_id
  end
end
