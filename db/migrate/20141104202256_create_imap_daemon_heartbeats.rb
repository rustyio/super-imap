class CreateImapDaemonHeartbeats < ActiveRecord::Migration
  def change
    create_table :imap_daemon_heartbeats do |t|
      t.string :tag

      t.timestamps
    end
  end
end
