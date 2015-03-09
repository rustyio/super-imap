ActiveAdmin.register DelayedJob do
  menu priority: 90
  config.sort_order = "created_at_desc"
  config.batch_actions = true

  # Only allow viewing and deleting.
  actions :all, :except => [:new, :edit]

  filter :handler
  filter :last_error
  filter :queue

  index do
    column "Handler" do |obj|
      link_to obj.handler.slice(0, 250), admin_delayed_job_path(obj)
    end
    column :created_at
    column :failed_at
    column :attempts
    column :queue
  end

  show do |obj|
    panel "Details" do
      attributes_table_for obj do
        row :id
        row :queue
        row :created_at
        row :failed_at if obj.attempts > 0
        row :attempts if obj.attempts > 0
        row :message do
          link_to "Download Message", message_admin_delayed_job_path(obj, "eml")
        end if /CallNewMailWebhook/.match(obj.handler)
      end
    end

    panel "Handler" do
      pre obj.handler
    end

    panel "Last Error" do
      pre obj.last_error
    end if obj.attempts > 0
  end

  member_action :message, :method => :get do
    # HACK - Make sure the class is loaded.
    CallNewMailWebhook

    job = YAML.load(resource.handler)
    if job.object.class == CallNewMailWebhook
      render :text => job.object.raw_eml, :content_type => 'message/rfc822'
    else
      render :text => "There was a problem."
    end
  end
end
