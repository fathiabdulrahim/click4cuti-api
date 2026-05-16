class AddProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :first_name,      :string
    add_column :users, :last_name,       :string
    add_column :users, :nric,            :string
    add_column :users, :nric_old,        :string
    add_column :users, :nric_color,      :string
    add_column :users, :date_of_birth,   :date
    add_column :users, :place_of_birth,  :string
    add_column :users, :race,            :string
    add_column :users, :religion,        :string
    add_column :users, :blood_type,      :string
    add_column :users, :education_level, :string
    add_column :users, :marital_status,  :string
    add_column :users, :nationality,     :string
    add_column :users, :bumi_status,     :string

    add_column :users, :driving_license_number, :string
    add_column :users, :driving_license_class,  :string
    add_column :users, :driving_license_expiry, :date

    add_index :users, [:nric, :company_id], unique: true, where: "nric IS NOT NULL"
  end
end
