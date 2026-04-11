class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :agency_id
      t.string  :name,                null: false
      t.string  :registration_number
      t.string  :hr_email,            null: false
      t.text    :address
      t.string  :state
      t.boolean :is_active,           null: false, default: true
      t.timestamps
    end

    add_index :companies, :agency_id
    add_index :companies, :registration_number, unique: true, where: "registration_number IS NOT NULL"
  end
end
