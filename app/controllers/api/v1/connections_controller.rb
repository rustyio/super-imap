class Api::V1::ConnectionsController < ApplicationController
  PartnerNotFoundError        = Class.new(StandardError)
  ConnectionTypeNotFoundError = Class.new(StandardError)
  ConnectionNotFoundError     = Class.new(StandardError)

  respond_to :json
  before_action :default_format_json
  before_action :load_context

  attr_accessor :partner

  def index
    @connections = self.partner.connections
  end

  def create
    @connection = self.partner.connections.
                  where_auth_mechanism(params[:auth_mechanism]).
                  create(params)
    render :show
  end

  def show
    @connection = self.partner.connections.
                  where_auth_mechanism(params[:auth_mechanism]).
                  first
    raise ConnectionNotFoundError.new unless @connection
  rescue ConnectionNotFoundError => e
    render :status => :not_found, :text => "Connection not found."
  end

  def destroy
    @connection = self.partner.connections.
                  where_auth_mechanism(params[:auth_mechanism]).
                  first
    @connection.update_attributes(:archived => true)
    render :no_content
  end

  private

  def default_format_json
    request.format = "json" unless params[:format]
  end

  def load_context
    load_partner
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
end
