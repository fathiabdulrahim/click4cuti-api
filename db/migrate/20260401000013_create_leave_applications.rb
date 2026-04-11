class CreateLeaveApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :leave_applications, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :user_id,             null: false
      t.uuid    :leave_type_id,       null: false
      t.uuid    :approved_by
      t.date    :start_date,          null: false
      t.date    :end_date,            null: false
      t.decimal :total_days,          null: false, precision: 8, scale: 2, default: "0.0"
      t.text    :reason,              null: false
      t.text    :extended_reason
      t.string  :status,              null: false, default: "PENDING"
      t.text    :reviewer_remarks
      t.boolean :requires_ceo_approval, null: false, default: false
      t.timestamps
    end

    add_index :leave_applications, [:user_id, :status]
    add_index :leave_applications, :leave_type_id
    add_index :leave_applications, :approved_by
    add_index :leave_applications, [:user_id, :created_at]
  end
end
