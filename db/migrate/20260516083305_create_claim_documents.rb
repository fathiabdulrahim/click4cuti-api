class CreateClaimDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :claim_documents, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :claim_application_id, null: false
      t.string :file_name, null: false
      t.string :content_type
      t.integer :file_size
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :claim_documents, :claim_application_id
    add_foreign_key :claim_documents, :claim_applications, column: :claim_application_id
  end
end
