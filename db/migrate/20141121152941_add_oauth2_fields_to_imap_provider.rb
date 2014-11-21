class AddOauth2FieldsToImapProvider < ActiveRecord::Migration
  def change
    add_column :imap_providers, :oauth2_authorize_url, :string
    add_column :imap_providers, :oauth2_response_type, :string
    add_column :imap_providers, :oauth2_access_type, :string
    add_column :imap_providers, :oauth2_approval_prompt, :string
  end
end
