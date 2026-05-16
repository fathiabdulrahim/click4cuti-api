class AddEaPersonInChargeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :ea_person_in_charge, type: :uuid, foreign_key: { to_table: :users }
  end
end
