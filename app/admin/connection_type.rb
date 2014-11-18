ActiveAdmin.register ImapProvider do
  config.sort_order = "auth_mechanism_asc"
  permit_params :auth_mechanism, :title, :host, :port, :use_ssl,
                *ImapProvider::Plain.connection_fields,
                *ImapProvider::Oauth1.connection_fields,
                *ImapProvider::Oauth2.connection_fields

  config.filters = false

  config.clear_action_items!
  actions :all, :except => [:edit, :destroy]

  index do
    column "Connection Type" do |obj|
      link_to "#{obj.title} (#{obj.auth_mechanism})", admin_imap_provider_path(obj)
    end

    column "Server" do |obj|
       "#{obj.host}:#{obj.port}"
    end
  end

  show do |obj|
    panel "Details" do
      attributes_table_for obj do
        row :auth_mechanism
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
