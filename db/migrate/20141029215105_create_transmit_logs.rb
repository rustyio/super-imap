class CreateTransmitLogs < ActiveRecord::Migration
  def change
    create_table :transmit_logs do |t|
      t.references :mail_log, index: true
      t.integer :response_code
      t.string :response_body

      t.timestamps
    end
  end
end
