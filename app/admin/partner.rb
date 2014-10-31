ActiveAdmin.register Partner do
  permit_params :name, :success_webhook, :failure_webhook

  breadcrumb do
    []
  end

  config.filters = false

  index do
    column :name
    actions
  end

  sidebar :links, :only => :show do
    partner = Partner.find(params[:id])
    link_to("Connections (#{partner.partner_connections_count})",
            admin_partner_partner_connections_path(partner))

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
