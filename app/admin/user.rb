ActiveAdmin.register User do
  belongs_to :partner_connection
  config.sort_order = "email_asc"
  permit_params :tag, :email,
                *Plain::User.connection_fields,
                *Oauth1::User.connection_fields,
                *Oauth2::User.connection_fields

  actions :all, :except => [:destroy]

  action_item :only => :show do
    if user.archived
      link_to('Restore User', restore_admin_partner_connection_user_path(params[:partner_connection_id], user.id))
    else
      link_to('Archive User', archive_admin_partner_connection_user_path(params[:partner_connection_id], user.id))
    end
  end

  member_action :archive, :method => :get do
    user = User.find(params[:id])
    user.update_attributes!(:archived => true)
    redirect_to({:action => :show}, {:notice => "User archived!"})
  end

  member_action :restore, :method => :get do
    user = User.find(params[:id])
    user.update_attributes!(:archived => false)
    redirect_to({:action => :show}, {:notice => "User restored!"})
  end

  breadcrumb do
    connection = PartnerConnection.find(params[:partner_connection_id])
    partner = connection.partner
    [
      link_to("Partners", admin_partners_path),
      link_to(partner.name, admin_partner_path(partner)),
      link_to("Connections", admin_partner_partner_connections_path(partner)),
      link_to(connection.imap_provider_code,
              admin_partner_partner_connection_path(partner, connection)),
      link_to("Users",
              admin_partner_connection_users_path(connection))
    ]
  end

  filter :email
  scope :active
  scope :archived

  index do
    column :tag do |obj|
      link_to obj.tag, admin_partner_connection_user_path(obj.connection, obj)
    end
    column :email do |obj|
      if obj.email
        link_to obj.email, admin_partner_connection_user_path(obj.connection, obj)
      end
    end
    column :links do |obj|
      link_to("Mail Logs (#{obj.mail_logs_count})",
              admin_user_mail_logs_path(obj))
    end
    column :connected_at
    column :last_login_at
    column :last_email_at
    column :archived
  end

  show do |obj|
    panel "Details" do
      attributes_table_for obj do
        row :id
        row :tag
        row :connected_at
        row :last_login_at
        row :last_email_at
        row :type
        row "Links" do
          link_to("Connect", new_users_connect_url(obj.signed_request_params)) +
            ", " +
            link_to("Disconnect", new_users_disconnect_url(obj.signed_request_params))
          # [
          # ].join(", ")
        end
        row :archived
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

  form do |f|
    f.inputs "Details" do
      f.input :tag
    end

    if !f.object.new_record? && f.object.connection_fields.present?
      f.inputs "Connection Settings" do
        f.object.connection_fields.each do |field|
          f.input field, :input_html => { :value => f.object.send(field) }
        end
      end
    end

    f.actions
  end
end
