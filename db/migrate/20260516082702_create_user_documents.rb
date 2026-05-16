class CreateUserDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :user_documents, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.text :remarks, null: false
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :user_documents, :user_id
    add_foreign_key :user_documents, :users, column: :user_id
  end
end
