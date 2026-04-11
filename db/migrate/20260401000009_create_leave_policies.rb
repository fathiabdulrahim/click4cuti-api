class CreateLeavePolicies < ActiveRecord::Migration[8.1]
  def change
    create_table :leave_policies, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :company_id,          null: false
      t.string  :name,                null: false
      t.text    :description
      t.integer :advance_notice_days, null: false, default: 7
      t.boolean :is_active,           null: false, default: true
      t.timestamps
    end

    add_index :leave_policies, :company_id
  end
end
