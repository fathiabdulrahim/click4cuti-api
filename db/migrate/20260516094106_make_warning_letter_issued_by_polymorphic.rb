class MakeWarningLetterIssuedByPolymorphic < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :warning_letters, column: :issued_by_id
    add_column :warning_letters, :issued_by_type, :string
    add_index  :warning_letters, [:issued_by_type, :issued_by_id]
  end

  def down
    remove_index  :warning_letters, [:issued_by_type, :issued_by_id]
    remove_column :warning_letters, :issued_by_type
    add_foreign_key :warning_letters, :users, column: :issued_by_id
  end
end
