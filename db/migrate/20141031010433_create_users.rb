class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.references :partner_connection, index: true
      t.string :email
      t.string :tag
      t.integer :mail_logs_count, :default => 0
      t.datetime :last_connected_at
      t.datetime :last_email_at
      t.integer :last_uid
      t.string :last_uid_validity
      t.string :last_internal_date
      t.string :login_username
      t.string :login_password
      t.string :oauth1_token
      t.string :oauth1_token_secret
      t.string :oauth2_refresh_token
      t.timestamps
    end
  end
end
