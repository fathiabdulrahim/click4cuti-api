class CreateHrAgencies < ActiveRecord::Migration[8.1]
  def change
    create_table :hr_agencies, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string  :name,       null: false
      t.string  :email,      null: false
      t.string  :phone
      t.text    :address
      t.boolean :is_active,  null: false, default: true
      t.timestamps
    end

    add_index :hr_agencies, :email, unique: true
  end
end
