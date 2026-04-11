class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_logs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid   :actor_id,   null: false
      t.string :actor_type, null: false  # AdminUser or User
      t.uuid   :company_id
      t.string :action,     null: false
      t.string :entity_type
      t.uuid   :entity_id
      t.text   :details
      t.string :ip_address
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :activity_logs, [:actor_id, :actor_type]
    add_index :activity_logs, :company_id
    add_index :activity_logs, :created_at
  end
end
