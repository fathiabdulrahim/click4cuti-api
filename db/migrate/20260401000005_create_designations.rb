class CreateDesignations < ActiveRecord::Migration[8.1]
  def change
    create_table :designations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :company_id,  null: false
      t.string  :title,       null: false
      t.boolean :is_manager,  null: false, default: false
      t.boolean :is_active,   null: false, default: true
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :designations, :company_id
  end
end
