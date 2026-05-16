class CreateBranches < ActiveRecord::Migration[8.1]
  def change
    create_table :branches, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :company_id, null: false
      t.string :name, null: false
      t.text :address
      t.string :state
      t.boolean :is_active, null: false, default: true
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :branches, :company_id
    add_foreign_key :branches, :companies, column: :company_id
  end
end
