ActiveAdmin.register User do
  belongs_to :partner_connection
  config.sort_order = "email_asc"
  permit_params :tag, :email,
                *User::Plain.connection_fields,
                *User::Oauth1.connection_fields,
                *User::Oauth2.connection_fields

  controller do
    alias_method :destroy_user, :destroy
    def destroy
      user = User.find(params[:id])
      user.update_attributes(:archived => true)
      redirect_to admin_partner_connection_user_path(params[:partner_connection_id], user.id)
    end
  end


  breadcrumb do
    connection = PartnerConnection.find(params[:partner_connection_id])
    partner = connection.partner
    [
      link_to("Partners", admin_partners_path),
      link_to(partner.name, admin_partner_path(partner)),
      link_to("Connections", admin_partner_partner_connections_path(partner)),
      link_to(connection.code,
              admin_partner_partner_connection_path(partner, connection)),
      link_to("Users",
              admin_partner_connection_users_path(connection))
    ]
  end

  filter :email
  scope :active
  scope :archived

  index do
    column :email do |obj|
      link_to "#{obj.email} (#{obj.tag})", admin_partner_connection_user_path(obj.connection, obj)
    end
    column :links do |obj|
      link_to("Mail Logs (#{obj.mail_logs_count})",
              admin_user_mail_logs_path(obj))
    end
    column :last_connected_at
    column :last_email_at
    column :archived
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
      f.input :email
    end

    f.inputs "Connection Settings", *f.object.connection_fields
    f.actions
  end
end
