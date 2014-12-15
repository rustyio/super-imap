class CreateTracerLogs < ActiveRecord::Migration
  def change
    create_table :tracer_logs do |t|
      t.references :user, index: true
      t.string :uid, :limit => 20
      t.datetime :detected_at

      t.timestamps
    end

    add_index :tracer_logs, :uid
  end
end
