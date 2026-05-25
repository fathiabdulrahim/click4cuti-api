class AddPendingCeoToLeaveApplicationStatus < ActiveRecord::Migration[8.1]
  # status is a plain string column — no PG enum to alter, index is on (user_id, status)
  # Adding PENDING_CEO as a valid value requires no DDL change; the Rails enum handles it.
  # This migration documents the intent and is a no-op at the DB level.
  def change
    # no-op: string column accepts any value; enum guard is in the model
  end
end
