class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :company_id,              null: false
      t.uuid    :department_id
      t.uuid    :designation_id
      t.uuid    :manager_id
      t.string  :employee_id
      t.string  :full_name,               null: false
      t.string  :email,                   null: false
      t.string  :phone
      t.text    :address
      t.string  :encrypted_password,      null: false, default: ""
      t.string  :role,                    null: false  # ADMIN, MANAGER, EMPLOYEE
      t.date    :join_date,               null: false
      t.string  :gender                                # MALE, FEMALE
      t.integer :number_of_children,      null: false, default: 0
      t.boolean :is_confirmed,            null: false, default: false
      t.boolean :is_active,               null: false, default: true

      # Devise recoverable
      t.string  :reset_password_token
      t.datetime :reset_password_sent_at

      # Devise trackable
      t.integer  :sign_in_count,          null: false, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      # JWT revocation
      t.string   :jti,                    null: false

      t.timestamps
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :jti,                  unique: true
    add_index :users, [:company_id, :is_active]
    add_index :users, [:employee_id, :company_id], unique: true, where: "employee_id IS NOT NULL"
    add_index :users, :manager_id
  end
end
