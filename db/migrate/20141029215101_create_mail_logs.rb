class CreateMailLogs < ActiveRecord::Migration
  def change
    create_table :mail_logs do |t|
      t.references :user, index: true
      t.string :message_id
      t.integer :transmit_logs_count, :default => 0

      t.timestamps
    end
  end
end
