ActiveAdmin.register ConnectionType do
  config.sort_order = "identifier_asc"

  config.filters = false

  index do
    column :identifier
    actions
  end

  show do |obj|
    panel "Test" do
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
