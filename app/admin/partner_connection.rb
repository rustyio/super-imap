ActiveAdmin.register PartnerConnection do
  belongs_to :partner

  permit_params :imap_provider_id, :oauth1_consumer_key,
                :oauth1_consumer_secret, :oauth2_client_id,
                :oauth2_client_secret

  breadcrumb do
    partner = Partner.find(params[:partner_id])
    [
      link_to("Partners", admin_partners_path),
      link_to(partner.name, admin_partner_path(partner)),
      link_to("Connections", admin_partner_partner_connections_path(partner))
    ]
  end

  config.filters = false

  index do
    column "Auth Mechanism" do |obj|
      link_to obj.auth_mechanism, admin_partner_partner_connection_path(obj.partner, obj)
    end

    column "Links" do |obj|
      raw [
        link_to("Connection Type",
                admin_imap_provider_path(obj)),
        link_to("Users (#{obj.users_count})",
                admin_partner_connection_users_path(obj))
      ].join(", ")
    end
    actions
  end

  show do |obj|
    panel "Details" do
      attributes_table_for obj do
        row :auth_mechanism
      end
    end
    panel "OAuth 1.0" do
      attributes_table_for obj do
        row :oauth1_consumer_key
        row :oauth1_consumer_secret
      end
    end
    panel "OAuth 2.0" do
      attributes_table_for obj do
        row :oauth2_client_id
        row :oauth2_client_secret
      end
    end
  end

  form do |f|
    f.inputs "Details" do
      f.input :imap_provider, :label => "Auth Mechanism"
    end if f.object.new_record?

    f.inputs "OAuth 1.0" do
      f.input :oauth1_consumer_key
      f.input :oauth1_consumer_secret
    end

    f.inputs "OAuth 2.0" do
      f.input :oauth2_client_id
      f.input :oauth2_client_secret
    end
    f.actions
  end
end
