ActiveAdmin.register AdminUser do
  permit_params :email, :password, :password_confirmation
  menu priority: 100
  config.sort_order = "email_asc"
  config.filters = false

  index do
    column :tag do |obj|
      link_to obj.email, admin_admin_user_path(obj)
    end
    column :last_sign_in_at
  end

  show do |obj|
    panel "Details" do
      attributes_table_for obj do
        row :id
        row :email
        row :sign_in_count
        row :current_sign_in_at
        row :current_sign_in_ip
        row :last_sign_in_at
        row :last_sign_in_ip
        row :created_at
      end
    end
  end

  form do |f|
    f.inputs "Admin Details" do
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end
