class CreatePartners < ActiveRecord::Migration
  def change
    create_table :partners do |t|
      t.string :api_key, :index => true
      t.string :name
      t.string :success_webhook
      t.string :failure_webhook
      t.integer :partner_connections_count, :default => 0

      t.timestamps
    end
  end
end
