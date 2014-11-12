ActiveAdmin.register Partner do
  menu :priority => 0
  permit_params :name, :api_key, :success_webhook, :failure_webhook

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

  show do
    attributes_table do
      row :name
      row :api_key
      row :success_webhook
      row :failure_webhook
    end
  end

  form do |f|
    f.inputs "Details" do
      f.input :name
      f.input :api_key
    end
    f.inputs "Webhooks" do
      f.input :success_webhook
      f.input :failure_webhook
    end
    f.actions
  end
end
