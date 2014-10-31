class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.references :partner_connection, index: true
      t.string :email
      t.string :tag
      t.integer :mail_logs_count, :default => 0
      t.datetime :last_connected_at
      t.datetime :last_email_at
      t.integer :last_imap_uid
      t.string :imap_uid_validity
      t.string :last_imap_email_date_at
      t.string :oauth1_token
      t.string :oauth1_token_secret
      t.string :oauth2_refresh_token

      t.timestamps
    end
  end
end
