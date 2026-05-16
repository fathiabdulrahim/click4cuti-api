class AddJobInfoEssentialsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :date_of_sign,          :date
    add_column :users, :employee_type,         :string
    add_column :users, :probation_period_days, :integer
    add_column :users, :oku_status,            :boolean, null: false, default: false
    add_reference :users, :branch, type: :uuid, foreign_key: true
  end
end
