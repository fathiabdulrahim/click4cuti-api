class ExtendWarningLettersForConduct < ActiveRecord::Migration[8.1]
  def up
    add_column :warning_letters, :source,       :string
    add_column :warning_letters, :details,      :text
    add_column :warning_letters, :action_taken, :text
    add_column :warning_letters, :issued_by_id, :uuid

    # Backfill existing rows
    execute "UPDATE warning_letters SET source = 'AUTO' WHERE source IS NULL"

    change_column_null :warning_letters, :source, false
    change_column_default :warning_letters, :source, "AUTO"
    change_column_null :warning_letters, :leave_type_id, true

    add_foreign_key :warning_letters, :users, column: :issued_by_id
    add_index :warning_letters, :issued_by_id

    execute <<~SQL
      ALTER TABLE warning_letters
      ADD CONSTRAINT warning_letters_source_check
      CHECK (source IN ('AUTO', 'MANUAL'))
    SQL
  end

  def down
    execute "ALTER TABLE warning_letters DROP CONSTRAINT IF EXISTS warning_letters_source_check"
    remove_foreign_key :warning_letters, column: :issued_by_id
    remove_index :warning_letters, :issued_by_id
    change_column_null :warning_letters, :leave_type_id, false
    remove_column :warning_letters, :issued_by_id
    remove_column :warning_letters, :action_taken
    remove_column :warning_letters, :details
    remove_column :warning_letters, :source
  end
end
