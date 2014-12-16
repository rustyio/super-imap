ActiveAdmin.register TracerLog do
  config.sort_order = "created_at_desc"

  # Only allow viewing.
  config.clear_action_items!
  actions :all, :except => [:new, :edit, :destroy]

  config.filters = false


  index do
    column :user
    column :uid do |obj|
      link_to obj.uid, admin_tracer_log_path(obj)
    end
    column :created_at
    column :detected_at
    column "Elapsed" do |obj|
      if obj.detected_at && obj.created_at
        seconds = obj.detected_at - obj.created_at
        "#{seconds.round(2)} s"
      end
    end
  end
end
