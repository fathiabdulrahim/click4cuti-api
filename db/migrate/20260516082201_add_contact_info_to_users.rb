class AddContactInfoToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :mobile_phone,            :string
    add_column :users, :personal_email,          :string
    add_column :users, :mailing_address,         :text
    add_column :users, :emergency_contact_name,  :string
    add_column :users, :emergency_contact_phone, :string
  end
end
