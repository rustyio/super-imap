class RemoveOauth1Fields < ActiveRecord::Migration
  def change
    remove_column :imap_providers, :oauth1_access_token_path
    remove_column :imap_providers, :oauth1_authorize_path
    remove_column :imap_providers, :oauth1_request_token_path
    remove_column :imap_providers, :oauth1_scope
    remove_column :imap_providers, :oauth1_site
    remove_column :partner_connections, :oauth1_consumer_key
    remove_column :partner_connections, :oauth1_consumer_secret
    remove_columns :users, :oauth1_token
    remove_columns :users, :oauth1_token_secret
  end
end
