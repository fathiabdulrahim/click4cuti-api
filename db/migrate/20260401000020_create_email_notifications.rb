class CreateEmailNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :email_notifications, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid   :company_id
      t.string :recipient_email,   null: false
      t.string :recipient_type,    null: false  # AdminUser or User
      t.uuid   :recipient_id,      null: false
      t.string :subject,           null: false
      t.text   :body,              null: false
      t.string :notification_type, null: false
      t.uuid   :reference_id
      t.string :reference_type
      t.string :delivery_status,   null: false, default: "PENDING"
      t.datetime :sent_at
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :email_notifications, :company_id
    add_index :email_notifications, [:recipient_id, :recipient_type]
    add_index :email_notifications, :delivery_status
  end
end
