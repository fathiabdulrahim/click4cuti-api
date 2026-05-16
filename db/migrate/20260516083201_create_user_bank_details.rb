class CreateUserBankDetails < ActiveRecord::Migration[8.1]
  def change
    create_table :user_bank_details, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.string :bank_name
      t.string :account_number
      t.string :account_type
      t.string :branch
      t.string :account_status
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :user_bank_details, :user_id, unique: true
    add_foreign_key :user_bank_details, :users, column: :user_id

    execute <<~SQL
      ALTER TABLE user_bank_details
      ADD CONSTRAINT user_bank_details_account_type_check
      CHECK (account_type IS NULL OR account_type IN ('SAVING', 'CURRENT', 'FIXED', 'OTHERS'))
    SQL

    execute <<~SQL
      ALTER TABLE user_bank_details
      ADD CONSTRAINT user_bank_details_account_status_check
      CHECK (account_status IS NULL OR account_status IN ('ACTIVE', 'INACTIVE'))
    SQL
  end
end
