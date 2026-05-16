class BackfillUserSupervisorsFromLeaveApprovers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      INSERT INTO user_supervisors (id, user_id, supervisor_id, category, level, created_at, updated_at)
      SELECT
        gen_random_uuid(),
        ula.user_id,
        ula.approver_id,
        'LEAVE',
        1,
        ula.created_at,
        ula.updated_at
      FROM user_leave_approvers ula
      ON CONFLICT (user_id, category, level) DO NOTHING
    SQL
  end

  def down
    execute "DELETE FROM user_supervisors WHERE category = 'LEAVE' AND level = 1"
  end
end
