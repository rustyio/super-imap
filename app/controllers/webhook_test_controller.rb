class WebhookTestController < ApplicationController
  layout "blank"
  skip_before_action :verify_authenticity_token

  attr_accessor :json_params, :user

  def new_mail
    Log.info request.body
    render :status => :ok, :text => "OK"
  end

  def user_connected
    Log.info request.body
    render :status => :ok, :text => "OK"
  end

  def user_disconnected
    Log.info request.body
    render :status => :ok, :text => "OK"
  end
end
