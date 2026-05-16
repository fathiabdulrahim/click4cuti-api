class CreateClaimApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :claim_applications, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.uuid :claim_type_id, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :claim_date, null: false
      t.text :reason, null: false
      t.string :status, null: false, default: "PENDING"
      t.uuid :approver_id
      t.string :approver_type
      t.text :reviewer_remarks
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :claim_applications, :user_id
    add_index :claim_applications, :claim_type_id
    add_index :claim_applications, [:user_id, :status]
    add_index :claim_applications, [:approver_type, :approver_id]
    add_foreign_key :claim_applications, :users, column: :user_id
    add_foreign_key :claim_applications, :claim_types, column: :claim_type_id

    execute <<~SQL
      ALTER TABLE claim_applications
      ADD CONSTRAINT claim_applications_status_check
      CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'))
    SQL
  end
end
