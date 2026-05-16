class AddInclusionToLeaveBalances < ActiveRecord::Migration[8.1]
  def change
    add_column :leave_balances, :is_included, :boolean, null: false, default: true
    add_column :leave_balances, :remarks,     :text
  end
end
