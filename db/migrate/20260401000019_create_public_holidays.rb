class CreatePublicHolidays < ActiveRecord::Migration[8.1]
  def change
    create_table :public_holidays, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :company_id,     null: false
      t.string  :name,           null: false
      t.date    :holiday_date,   null: false
      t.integer :year,           null: false
      t.boolean :is_mandatory,   null: false, default: false
      t.boolean :is_replacement, null: false, default: false
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :public_holidays, [:company_id, :year]
    add_index :public_holidays, [:company_id, :holiday_date], unique: true
  end
end
