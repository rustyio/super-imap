ActiveAdmin.register TransmitLog do
  belongs_to :mail_log

  config.sort_order = "created_at_desc"

  # Only allow viewing.
  config.clear_action_items!
  actions :all, :except => [:edit, :destroy]

  filter :response_code
  filter :response_body

  breadcrumb do
    mail_log   = MailLog.find(params[:mail_log_id])
    user       = mail_log.user
    connection = user.partner_connection
    partner    = connection.partner
    [
      link_to("Partners", admin_partners_path),
      link_to(partner.name, admin_partner_path(partner)),
      link_to("Connections", admin_partner_partner_connections_path(partner)),
      link_to(connection.connection_type.identifier, admin_partner_partner_connection_path(partner, connection)),
      link_to("Users", admin_partner_connection_users_path(connection)),
      link_to(user.email, admin_partner_connection_user_path(connection, user)),
      link_to("Mail Logs", admin_user_mail_logs_path(user)),
      link_to(mail_log.id, admin_user_mail_log_path(user, mail_log)),
      link_to("Transmit Logs", admin_mail_log_transmit_logs_path(mail_log))
    ]
  end

  index do
    column :response_code
    column :response_body
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :created_at
      row :response_code
      row :response_body
    end
  end
end
