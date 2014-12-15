ActiveAdmin.register ImapProvider do
  config.sort_order = "code_asc"
  permit_params :code, :title,
                :imap_host, :imap_port, :imap_use_ssl,
                :smtp_host, :smtp_port, :smtp_domain, :smtp_enable_starttls_auto,
                *Plain::ImapProvider.connection_fields,
                *Oauth2::ImapProvider.connection_fields

  config.filters = false

  config.clear_action_items!
  actions :all, :except => [:edit, :destroy]

  index do
    column "Connection Type" do |obj|
      link_to "#{obj.title} (#{obj.code})", admin_imap_provider_path(obj)
    end

    column "IMAP Server" do |obj|
       "#{obj.imap_host}:#{obj.imap_port}"
    end

    column "SMTP Server" do |obj|
       "#{obj.smtp_host}:#{obj.smtp_port}"
    end
  end

  show do |obj|
    panel "Details" do
      attributes_table_for obj do
        row :code
        row :title
        row :type
      end
    end

    panel "IMAP Settings" do
      attributes_table_for obj do
        row :imap_host
        row :imap_port
        row :imap_use_ssl
      end
    end

    panel "SMTP Settings" do
      attributes_table_for obj do
        row :smtp_host
        row :smtp_port
        row :smtp_domain
        row :smtp_enable_starttls_auto
      end
    end

    panel "Connection Settings" do
      attributes_table_for obj do
        obj.connection_fields.map do |field|
          row field
        end
      end
    end if obj.connection_fields.present?
  end
end
