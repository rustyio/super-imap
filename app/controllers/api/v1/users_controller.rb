class Api::V1::UsersController < ApplicationController
  PartnerNotFoundError    = Class.new(StandardError)
  ConnectionNotFoundError = Class.new(StandardError)
  UserNotFoundError       = Class.new(StandardError)

  respond_to :json
  before_action :default_format_json
  before_action :load_context

  attr_accessor :partner, :connection

  def index
    @users = self.connection.users.order(:email)
  end

  def create
    @user = self.connection.users.create(params)
    render :show
  end

  def show
    @user = self.connection.users.find_by_tag(params[:id])
    raise UserNotFoundError.new unless @user
  rescue UserNotFoundError => e
    render :status => :not_found, :text => "User not found. Check the tag."
  end

  def destroy
    @user = self.connection.users.find_by_tag(params[:id])
    @user.update_attributes(:archived => true)
    render :no_content
  end

  private

  def default_format_json
    request.format = "json" unless params[:format]
  end

  def load_context
    load_partner
    load_connection
  rescue PartnerNotFoundError => e
    render :status => :not_found, :text => "Partner not found. Check your api_key."
  rescue ConnectionNotFoundError => e
    render :status => :not_found, :text => "Connection not found."
  end

  def load_partner
    api_key = params[:api_key]
    self.partner = Partner.find_by_api_key(params[:api_key])
    raise PartnerNotFoundError.new("Missing or invalid api_key parameter.") unless self.partner
  end

  def load_connection
    # Look up the connection.
    conn_id = params[:connection_id]
    self.connection = self.partner.connections.where(:id => conn_id).first
    raise ConnectionNotFoundError.new unless self.connection
  end
end
