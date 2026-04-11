class CreateAdminUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_users, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :agency_id
      t.uuid    :company_id
      t.string  :full_name,               null: false
      t.string  :email,                   null: false
      t.string  :phone
      t.string  :encrypted_password,      null: false, default: ""
      t.string  :scope,                   null: false  # SUPER_ADMIN, AGENCY, COMPANY
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

    add_index :admin_users, :email,                unique: true
    add_index :admin_users, :reset_password_token, unique: true
    add_index :admin_users, :jti,                  unique: true
    add_index :admin_users, :agency_id
    add_index :admin_users, :company_id
  end
end
