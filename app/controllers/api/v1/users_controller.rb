class Api::V1::UsersController < ApplicationController
  layout "blank"
  respond_to :json
  skip_before_action :verify_authenticity_token
  before_action :default_format_json
  before_action :load_partner
  before_action :load_imap_provider
  before_action :load_connection
  before_action :load_user, :only => [:update, :show, :destroy]

  attr_accessor :partner, :imap_provider, :connection, :user

  def index
    @users = self.connection.users.order(:email)
  end

  def create
    self.user = self.connection.new_typed_user
    self.user.update_attributes!(user_params)
    render :show
  rescue ActiveRecord::RecordInvalid => e
    render :status => :bad_request, :text => e.to_s
  end

  def update
    self.user.update_attributes!(user_params)
    render :show
  rescue ActiveRecord::RecordInvalid => e
    render :status => :bad_request, :text => e.to_s
  end

  def show
    # pass
  end

  def destroy
    self.user.update_attributes(:archived => true)
    render :status => :no_content, :text => "Archived user."
  end

  private

  def default_format_json
    request.format = "json" unless params[:format]
  end

  def load_partner
    api_key = request.headers['x-api-key'] || params[:api_key]
    self.partner = Partner.find_by_api_key(api_key)
    if partner.nil?
      render :status => :not_found, :text => "Partner not found. Check your api_key."
    end
  end

  def load_imap_provider
    code = params[:connection_imap_provider_code]
    self.imap_provider = ImapProvider.find_by_code(code)
    if self.imap_provider.nil?
      render :status => :not_found, :text => "Imap Provider not found for '#{code}'."
    end
  end

  def load_connection
    self.connection = self.partner.connections.find_by_imap_provider_id(self.imap_provider.id)
    if self.connection.nil?
      render :status => :not_found, :text => "Connection not found."
    end
  end

  def load_user
    tag = params[:tag]
    self.user = self.connection.users.find_by_tag(tag)
    if self.user.nil?
      render :status => :not_found, :text => "User not found for '#{tag}'."
    end
  end

  def user_params
    if self.user
      params.permit([:tag, :email, :archived] + self.user.connection_fields)
    else
      params.permit([:tag, :email, :archived])
    end
  end
end
