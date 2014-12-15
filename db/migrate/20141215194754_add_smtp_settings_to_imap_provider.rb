class AddSmtpSettingsToImapProvider < ActiveRecord::Migration
  def change
    rename_column :imap_providers, :host, :imap_host
    rename_column :imap_providers, :port, :imap_port
    rename_column :imap_providers, :use_ssl, :imap_use_ssl
    add_column :imap_providers, :smtp_host, :string
    add_column :imap_providers, :smtp_port, :integer
    add_column :imap_providers, :smtp_domain, :string
    add_column :imap_providers, :smtp_enable_starttls_auto, :boolean
  end
end
