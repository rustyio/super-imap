ActiveAdmin.register User do
  belongs_to :partner_connection
  config.sort_order = "email_asc"

  # Only allow viewing.
  config.clear_action_items!
  actions :all, :except => [:edit, :destroy]

  breadcrumb do
    connection = PartnerConnection.find(params[:partner_connection_id])
    partner = connection.partner
    [
      link_to("Partners", admin_partners_path),
      link_to(partner.name, admin_partner_path(partner)),
      link_to("Connections", admin_partner_partner_connections_path(partner)),
      link_to(connection.connection_type.identifier,
              admin_partner_partner_connection_path(partner, connection)),
      link_to("Users",
              admin_partner_connection_users_path(connection))
    ]
  end

  filter :email

  index do
    column :email do |obj|
      link_to obj.email, admin_partner_connection_user_path(obj.connection, obj)
    end
    column :links do |obj|
      link_to("Mail Logs (#{obj.mail_logs_count})",
              admin_user_mail_logs_path(obj))
    end
    column :last_connected_at
    column :last_email_at
    actions
  end

  show do |obj|
    panel "Details" do
      attributes_table_for obj do
        row :id
        row :email
        row :tag
        row :last_connected_at
        row :last_email_at
        row :archived
      end
    end
  end
end
