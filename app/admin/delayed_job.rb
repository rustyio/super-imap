ActiveAdmin.register DelayedJob do
  menu priority: 90
  config.sort_order = "created_at_desc"

  # Only allow viewing.
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
      end
    end

    panel "Handler" do
      pre obj.handler
    end

    panel "Last Error" do
      pre obj.last_error
    end if obj.attempts > 0
end

  # form do |f|
  #   f.inputs "Admin Details" do
  #     f.input :email
  #     f.input :password
  #     f.input :password_confirmation
  #   end
  #   f.actions
  # end
end
