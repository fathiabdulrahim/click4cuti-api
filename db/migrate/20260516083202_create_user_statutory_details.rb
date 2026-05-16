class CreateUserStatutoryDetails < ActiveRecord::Migration[8.1]
  def change
    create_table :user_statutory_details, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.string  :epf_number
      t.string  :epf_contribution_start
      t.string  :socso_number
      t.integer :socso_contribution_start_age
      t.decimal :eis_employee_rate, precision: 5, scale: 4
      t.decimal :eis_employer_rate, precision: 5, scale: 4
      t.string  :income_tax_number
      t.decimal :vola_amount, precision: 10, scale: 2
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :user_statutory_details, :user_id, unique: true
    add_foreign_key :user_statutory_details, :users, column: :user_id

    execute <<~SQL
      ALTER TABLE user_statutory_details
      ADD CONSTRAINT user_statutory_details_epf_start_check
      CHECK (epf_contribution_start IS NULL OR
             epf_contribution_start IN ('BEFORE_1998_AUG', 'AFTER_1998_AUG', 'AFTER_2001_AUG'))
    SQL
  end
end
