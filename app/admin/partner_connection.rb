ActiveAdmin.register PartnerConnection do
  belongs_to :partner
  config.sort_order="name_asc"

  breadcrumb do
    partner = Partner.find(params[:partner_id])
    [
      link_to("Partners", admin_partners_path),
      link_to(partner.name, admin_partner_path(partner))
    ]
  end

  config.filters = false

  index do
    column :name do |obj|
      "#{obj.connection_type.identifier} (#{obj.id})"
    end
    actions
  end

  sidebar :links, :only => :show do
    connection = PartnerConnection.find(params[:id])
    raw [
      link_to("Connection Type",
              admin_connection_type_path(connection)),
      link_to("Users (#{connection.users_count})",
              admin_partner_connection_users_path(connection))
    ].join("<br>")
  end

  show do |ad|
    attributes_table do
      row :oauth1_consumer_key
      row :oauth1_consumer_secret
      row :oauth2_client
      row :oauth2_client_secret
    end
  end
end
