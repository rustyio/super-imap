class Api::V1::ConnectionsController < ApplicationController
  PartnerNotFoundError      = Class.new(StandardError)
  ImapProviderNotFoundError = Class.new(StandardError)
  ConnectionNotFoundError   = Class.new(StandardError)

  respond_to :json
  before_action :default_format_json
  before_action :load_partner
  before_action :load_imap_provider, :only => [:create, :update, :show, :destroy]
  before_action :load_connection, :only => [:update, :show, :destroy]

  attr_accessor :partner, :imap_provider, :connection

  def index
    @connections = self.partner.connections
  end

  def create
    self.connection = self.partner.connections.where(:imap_provider_id => imap_provider.id).build
    self.connection.update_attributes!(connection_params)
    render :show
  rescue ActiveRecord::RecordInvalid => e
    render :status => :bad_request, :text => e.to_s
  end

  def update
    self.connection.update_attributes!(connection_params)
    render :show
  rescue ActiveRecord::RecordInvalid => e
    render :status => :bad_request, :text => e.to_s
  end

  def show
    # Pass.
  end

  def destroy
    self.connection.destroy
    render :status => :no_content, :text => "Deleted connection."
  end

  private

  def default_format_json
    request.format = "json" unless params[:format]
  end

  def load_partner
    api_key = params[:api_key]
    self.partner = Partner.find_by_api_key(params[:api_key])
    if self.partner.nil?
      render :status => :not_found, :text => "Partner not found. Check your api_key."
    end
  end

  def load_imap_provider
    code = params[:imap_provider_code]
    self.imap_provider = ImapProvider.find_by_code(code)
    if self.imap_provider.nil?
      render :status => :not_found, :text => "Imap Provider not found for '#{code}'."
    end
  end

  def load_connection
    self.connection = self.partner.connections.where(:imap_provider_id => imap_provider.id).first
    if self.connection.nil?
      render :status => :not_found, :text => "Connection not found."
    end
  end

  def connection_params
    if self.connection
      params.permit(self.connection.connection_fields)
    else
      params.permit()
    end
  end
end
