class AddMoreIndexesToMailLogs < ActiveRecord::Migration
  def up
    add_index :mail_logs, [:user_id, :message_id]
    add_index :mail_logs, [:user_id, :sha1_id]
  end

  def down
  end
end
