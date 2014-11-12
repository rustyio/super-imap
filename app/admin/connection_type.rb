ActiveAdmin.register ConnectionType do
  config.sort_order = "identifier_asc"
  permit_params :identifier, :title, :host, :port, :use_ssl,
                :oauth1_access_token_path, :oauth1_authorize_path,
                :oauth1_request_token_path, :oauth1_scope, :oauth1_site,
                :oauth2_grant_type, :oauth2_scope, :oauth2_site,
                :oauth2_token_method, :oauth2_token_url

  config.filters = false

  index do
    column "Connection Type" do |obj|
      link_to "#{obj.identifier} - #{obj.title}", admin_connection_type_path(obj)
    end
    column "Server" do |obj|
       "#{obj.host}:#{obj.port}"
    end
    actions
  end

  show do |obj|
    panel "Details" do
      attributes_table_for obj do
        row :identifier
        row :host
        row :port
        row :use_ssl
      end
    end
    panel "OAUTH 1.0" do
      attributes_table_for obj do
        row :oauth1_access_token_path
        row :oauth1_authorize_path
        row :oauth1_request_token_path
        row :oauth1_scope
        row :oauth1_site
      end
    end

    panel "OAUTH 2.0" do
      attributes_table_for obj do
        row :oauth2_grant_type
        row :oauth2_scope
        row :oauth2_site
        row :oauth2_token_method
        row :oauth2_token_url
      end
    end
  end

  form do |f|
    f.inputs "Details" do
      f.input :identifier
      f.input :host
      f.input :port
      f.input :use_ssl
    end

    f.inputs "OAUTH 1.0" do
      f.input :oauth1_access_token_path
      f.input :oauth1_authorize_path
      f.input :oauth1_request_token_path
      f.input :oauth1_scope
      f.input :oauth1_site
    end

    f.inputs "OAUTH 2.0" do
      f.input :oauth2_grant_type
      f.input :oauth2_scope
      f.input :oauth2_site
      f.input :oauth2_token_method
      f.input :oauth2_token_url
    end

    f.actions
  end
end
