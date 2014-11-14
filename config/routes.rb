Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  namespace :api do
    namespace :v1 do
      resources :connections, { :param => :auth_mechanism } do
        resources :users
      end
    end
  end
end
