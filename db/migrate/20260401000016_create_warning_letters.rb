class CreateWarningLetters < ActiveRecord::Migration[8.1]
  def change
    create_table :warning_letters, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :user_id,          null: false
      t.uuid    :company_id,       null: false
      t.uuid    :leave_type_id,    null: false
      t.string  :reason,           null: false
      t.integer :year,             null: false
      t.date    :issued_date,      null: false
      t.boolean :acknowledged,     null: false, default: false
      t.datetime :acknowledged_at
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :warning_letters, :user_id
    add_index :warning_letters, :company_id
    add_index :warning_letters, [:user_id, :year]
  end
end
