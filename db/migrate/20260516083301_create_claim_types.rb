class CreateClaimTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :claim_types, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :company_id, null: false
      t.string :name, null: false
      t.string :code
      t.text :description
      t.decimal :default_application_limit, precision: 12, scale: 2
      t.decimal :default_annual_limit,      precision: 12, scale: 2
      t.boolean :requires_document, null: false, default: false
      t.boolean :is_active, null: false, default: true
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :claim_types, :company_id
    add_index :claim_types, [:company_id, :name], unique: true
    add_foreign_key :claim_types, :companies, column: :company_id
  end
end
