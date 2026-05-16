class CreateFamilyMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :family_members, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.string :relation, null: false
      t.string :first_name, null: false
      t.string :last_name
      t.string :gender, null: false
      t.string :nric_or_passport
      t.date :date_of_birth, null: false
      t.string :phone
      t.string :email
      t.text :address
      t.string :employment_status, null: false
      t.boolean :oku_status, null: false, default: false
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :family_members, :user_id
    add_index :family_members, [:user_id, :relation]
    add_foreign_key :family_members, :users, column: :user_id

    execute <<~SQL
      ALTER TABLE family_members
      ADD CONSTRAINT family_members_relation_check
      CHECK (relation IN ('SPOUSE', 'CHILD', 'PARENT'))
    SQL

    execute <<~SQL
      ALTER TABLE family_members
      ADD CONSTRAINT family_members_employment_status_check
      CHECK (employment_status IN ('WORKING', 'NOT_WORKING', 'STUDYING', 'RETIRED'))
    SQL
  end
end
