ActiveAdmin.register Partner do
  menu :priority => 0
  permit_params :name, :api_key,
                :success_url, :failure_url,
                :new_mail_webhook,
                :user_connected_webhook,
                :user_disconnected_webhook

  breadcrumb do
    [
      link_to("Partners", admin_partners_path)
    ]
  end

  config.filters = false

  index do
    column :name do |partner|
      link_to partner.name, admin_partner_path(partner)
    end
    column :links do |partner|
      link_to("Connections (#{partner.partner_connections_count})",
              admin_partner_partner_connections_path(partner))
    end

    actions
  end

  show do |obj|
    panel "Connection Settings" do
      attributes_table_for obj do
        row :name
        row :api_key
      end
    end

    panel "Client Side Redirects" do
      attributes_table_for obj do
        row :success_url
        row :failure_url
      end
    end

    panel "Webhooks" do
      attributes_table_for obj do
        row :user_connected_webhook
        row :user_disconnected_webhook
        row :new_mail_webhook
      end
    end
  end

  form do |f|
    f.inputs "Details" do
      f.input :name
      f.input :api_key unless f.object.new_record?
    end

    f.inputs "Client Side Redirects" do
      f.input :success_url
      f.input :failure_url
    end

    f.inputs "Webhooks" do
      f.input :user_connected_webhook
      f.input :user_disconnected_webhook
      f.input :new_mail_webhook
    end
    f.actions
  end
end
