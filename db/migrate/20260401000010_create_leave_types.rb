class CreateLeaveTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :leave_types, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :leave_policy_id,       null: false
      t.string  :name,                  null: false
      t.string  :category,              null: false  # MANDATORY, SPECIAL
      t.integer :default_days_tier1,    null: false, default: 0
      t.integer :default_days_tier2,    null: false, default: 0
      t.integer :default_days_tier3,    null: false, default: 0
      t.integer :max_consecutive_days
      t.boolean :requires_document,     null: false, default: false
      t.boolean :allows_half_day,       null: false, default: true
      t.boolean :allows_carry_forward,  null: false, default: false
      t.integer :max_carry_forward_days
      t.integer :max_times_per_year
      t.uuid    :shared_balance_with
      t.boolean :is_active,             null: false, default: true
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :leave_types, :leave_policy_id
    add_index :leave_types, :shared_balance_with
  end
end
