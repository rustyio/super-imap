Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  namespace :api do
    namespace :v1 do
      resources :connections, { :param => :imap_provider_code } do
        resources :users, { :param => :tag }
      end
    end
  end

  namespace :users do
    resource :connect, :only => [:new] do
      get :callback
    end

    resource :disconnect, :only => [:new] do
      get :callback
    end
  end
end
