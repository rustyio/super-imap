class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :ensure_secure

  def ensure_secure
    if !request.ssl? && Rails.env.production?
      redirect_to request.original_url.gsub(/^http:/, "https:")
    end
  end
end
