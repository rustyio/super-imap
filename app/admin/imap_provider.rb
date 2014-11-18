ActiveAdmin.register ImapProvider do
  config.sort_order = "code_asc"
  permit_params :code, :title, :host, :port, :use_ssl,
                *Plain::ImapProvider.connection_fields,
                *Oauth1::ImapProvider.connection_fields,
                *Oauth2::ImapProvider.connection_fields

  config.filters = false

  config.clear_action_items!
  actions :all, :except => [:edit, :destroy]

  index do
    column "Connection Type" do |obj|
      link_to "#{obj.title} (#{obj.code})", admin_imap_provider_path(obj)
    end

    column "Server" do |obj|
       "#{obj.host}:#{obj.port}"
    end
  end

  show do |obj|
    panel "Details" do
      attributes_table_for obj do
        row :code
        row :title
        row :host
        row :port
        row :use_ssl
        row :type
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
