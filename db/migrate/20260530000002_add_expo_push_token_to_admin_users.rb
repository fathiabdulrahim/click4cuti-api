class AddExpoPushTokenToAdminUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :admin_users, :expo_push_token, :string
  end
end
