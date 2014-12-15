class PartnerConnection < ActiveRecord::Base
  include ConnectionFields

  # Magic.
  before_validation :fix_type

  # Relations.
  belongs_to :partner, :counter_cache => true
  belongs_to :imap_provider, :counter_cache => true
  has_many :users, :dependent => :destroy

  # Validation.
  validates_presence_of :imap_provider_id
  validates_uniqueness_of :imap_provider_id, :scope => :partner_id

  # Public: Used by ActiveAdmin.
  def display_name
    self.imap_provider_code
  end

  def imap_provider_code
    self.imap_provider.code
  end

  # Public: Create a new user that bases it's type on the
  # PartnerConnection type. In other words, if this is an
  # Oauth2::PartnerConnection, then return an Oauth2::User.
  def new_typed_user
    user = self.imap_provider.class_for(User).new
    self.users << user
    user
  end

  private

  # Private: Automatically set the STI type based on the imap_provider.
  def fix_type
    self.type ||= self.imap_provider.class_for(PartnerConnection).to_s
  end
end
