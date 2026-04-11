class CreateLeaveDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :leave_documents, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :leave_application_id, null: false
      t.string  :file_name,            null: false
      t.string  :file_path
      t.string  :content_type
      t.integer :file_size
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :leave_documents, :leave_application_id
  end
end
