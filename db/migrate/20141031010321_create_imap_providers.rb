class CreateImapProviders < ActiveRecord::Migration
  def change
    create_table :imap_providers do |t|
      t.string :code
      t.string :title
      t.integer :partner_connections_count
      t.string :host
      t.integer :port
      t.boolean :use_ssl
      t.string :oauth1_access_token_path
      t.string :oauth1_authorize_path
      t.string :oauth1_request_token_path
      t.string :oauth1_scope
      t.string :oauth1_site
      t.string :oauth2_grant_type
      t.string :oauth2_scope
      t.string :oauth2_site
      t.string :oauth2_token_method
      t.string :oauth2_token_url

      t.timestamps
    end
  end
end
