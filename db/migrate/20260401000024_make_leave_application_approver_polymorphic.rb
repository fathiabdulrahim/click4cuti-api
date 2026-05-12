class MakeLeaveApplicationApproverPolymorphic < ActiveRecord::Migration[8.1]
  def up
    rename_column :leave_applications, :approved_by, :approver_id
    add_column    :leave_applications, :approver_type, :string

    execute <<~SQL
      UPDATE leave_applications
      SET approver_type = 'User'
      WHERE approver_id IS NOT NULL
    SQL

    if index_exists?(:leave_applications, :approver_id, name: "index_leave_applications_on_approved_by")
      rename_index :leave_applications, "index_leave_applications_on_approved_by", "index_leave_applications_on_approver_id"
    end

    add_index :leave_applications, [:approver_type, :approver_id], name: "index_leave_applications_on_approver_type_and_approver_id"
  end

  def down
    remove_index  :leave_applications, name: "index_leave_applications_on_approver_type_and_approver_id"
    remove_column :leave_applications, :approver_type
    rename_column :leave_applications, :approver_id, :approved_by

    if index_exists?(:leave_applications, :approved_by, name: "index_leave_applications_on_approver_id")
      rename_index :leave_applications, "index_leave_applications_on_approver_id", "index_leave_applications_on_approved_by"
    end
  end
end
