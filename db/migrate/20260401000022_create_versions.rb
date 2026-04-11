class CreateVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :versions do |t|
      t.string   :item_type,      null: false
      t.uuid     :item_id,        null: false
      t.string   :event,          null: false
      t.string   :whodunnit
      t.jsonb    :object
      t.jsonb    :object_changes
      t.uuid     :company_id
      t.string   :request_ip
      t.string   :status_change
      t.datetime :created_at,     null: false
    end

    add_index :versions, [:item_type, :item_id]
    add_index :versions, [:company_id, :created_at]
    add_index :versions, :whodunnit
  end
end
