ActiveAdmin.register User do
  config.sort_order = "email_asc"

  belongs_to :partner_connection

  breadcrumb do
    connection = PartnerConnection.find(params[:partner_connection_id])
    partner = connection.partner
    [
      link_to("Partners", admin_partners_path),
      link_to(partner.name, admin_partner_path(partner)),
      link_to(connection.connection_type.identifier,
              admin_partner_partner_connection_path(partner, connection))
    ]
  end

  filter :email

  sidebar :links, :only => :show do
    user = User.find(params[:id])
    link_to("Mail Logs (#{user.mail_logs_count})",
            admin_user_mail_logs_path(user))
  end

  index do
    column :email
    column :last_connected_at
    column :last_email_at

    actions
  end
end
