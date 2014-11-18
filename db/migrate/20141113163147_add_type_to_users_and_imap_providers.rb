class AddTypeToUsersAndImapProviders < ActiveRecord::Migration
  def change
    add_column :imap_providers, :type, :string
    add_column :users, :type, :string
  end
end
