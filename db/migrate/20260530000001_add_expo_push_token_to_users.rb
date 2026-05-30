class AddExpoPushTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :expo_push_token, :string
  end
end
