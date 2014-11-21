class Users::ConnectsController < ApplicationController
  include Plain::ConnectsHelper
  include Oauth1::ConnectsHelper
  include Oauth2::ConnectsHelper

  before_action :load_user
  before_action :validate_signature

  attr_accessor :user

  def new
    apply_helper
  end

  def create
    apply_helper
  end

  def success
    apply_helper
  end

  def failure
    apply_helper
  end

  private

  def apply_helper
    helper = self.user.imap_provider.helper_for(params[:action])
    self.send(helper)
  end

  def load_user
    self.user = User.find_by_id(params[:user_id])
    if self.user.nil?
      render :status => :not_found, :text => "User not found."
    end
  end

  def validate_signature
    unless self.user.valid_signature?(params)
      render :status => :not_found, :text => "User not found."
    end
  end
end
