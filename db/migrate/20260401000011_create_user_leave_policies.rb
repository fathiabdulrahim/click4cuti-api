class CreateUserLeavePolicies < ActiveRecord::Migration[8.1]
  def change
    create_table :user_leave_policies, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id,         null: false
      t.uuid :leave_policy_id, null: false
      t.date :effective_from,  null: false
      t.date :effective_to
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :user_leave_policies, [:user_id, :leave_policy_id]
    add_index :user_leave_policies, :leave_policy_id
  end
end
