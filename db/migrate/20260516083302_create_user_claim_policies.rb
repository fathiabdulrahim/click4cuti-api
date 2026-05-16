class CreateUserClaimPolicies < ActiveRecord::Migration[8.1]
  def change
    create_table :user_claim_policies, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.uuid :claim_type_id, null: false
      t.decimal :application_limit, precision: 12, scale: 2
      t.decimal :annual_limit,      precision: 12, scale: 2
      t.boolean :is_unlimited_application, null: false, default: false
      t.boolean :is_unlimited_annual,      null: false, default: false
      t.boolean :is_included, null: false, default: true
      t.text :remarks
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :user_claim_policies, [:user_id, :claim_type_id], unique: true
    add_foreign_key :user_claim_policies, :users, column: :user_id
    add_foreign_key :user_claim_policies, :claim_types, column: :claim_type_id
  end
end
