class CreatePartnerConnections < ActiveRecord::Migration
  def change
    create_table :partner_connections do |t|
      t.references :partner, index: true
      t.references :imap_provider, index: true
      t.integer :users_count, :default => 0
      t.string :oauth1_consumer_key
      t.string :oauth1_consumer_secret
      t.string :oauth2_client_id
      t.string :oauth2_client_secret

      t.timestamps
    end
  end
end
