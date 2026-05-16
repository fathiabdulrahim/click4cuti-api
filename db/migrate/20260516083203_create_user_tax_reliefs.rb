class CreateUserTaxReliefs < ActiveRecord::Migration[8.1]
  def change
    create_table :user_tax_reliefs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.boolean :spouse_is_working
      t.boolean :spouse_is_disabled
      t.string  :spouse_gender
      t.boolean :contributes_to_sip, null: false, default: false
      t.string  :tax_category
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :user_tax_reliefs, :user_id, unique: true
    add_foreign_key :user_tax_reliefs, :users, column: :user_id

    execute <<~SQL
      ALTER TABLE user_tax_reliefs
      ADD CONSTRAINT user_tax_reliefs_spouse_gender_check
      CHECK (spouse_gender IS NULL OR spouse_gender IN ('MALE', 'FEMALE'))
    SQL

    execute <<~SQL
      ALTER TABLE user_tax_reliefs
      ADD CONSTRAINT user_tax_reliefs_category_check
      CHECK (tax_category IS NULL OR tax_category IN ('REGULAR', 'REP', 'KNOWLEDGE_WORKER'))
    SQL
  end
end
