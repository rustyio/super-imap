ActiveAdmin.register MailLog do
  belongs_to :user

  config.sort_order = "created_at_desc"

  # Only allow viewing.
  config.clear_action_items!
  actions :all, :except => [:edit, :destroy]

  config.filters = false

  breadcrumb do
    user = User.find(params[:user_id])
    connection = user.partner_connection
    partner = connection.partner
    [
      link_to("Partners", admin_partners_path),
      link_to(partner.name, admin_partner_path(partner)),
      link_to("Connections", admin_partner_partner_connections_path(partner)),
      link_to(connection.connection_type.identifier, admin_partner_partner_connection_path(partner, connection)),
      link_to("Users", admin_partner_connection_users_path(connection)),
      link_to(user.email, admin_partner_connection_user_path(connection, user)),
      link_to("Mail Logs", admin_user_mail_logs_path(user))
    ]
  end

  index do
    column :created_at
    column "Message ID" do |obj|
      link_to obj.message_id, admin_user_mail_log_path(obj.user, obj)
    end
    column "Links" do |obj|
      link_to("Transmit Logs (#{obj.transmit_logs_count})", admin_mail_log_transmit_logs_path(obj))
    end
    actions
  end

  show do
    attributes_table do
      row :created_at
      row :id
      row :message_id
    end
  end
end
