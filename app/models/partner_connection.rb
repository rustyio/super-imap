class PartnerConnection < ActiveRecord::Base
  include ConnectionFields

  belongs_to :partner, :counter_cache => true
  belongs_to :imap_provider, :counter_cache => true
  has_many :users, :dependent => :destroy

  validates_presence_of :imap_provider_id
  validates_uniqueness_of :imap_provider_id, :scope => :partner_id
  before_validation :fix_type

  def fix_type
    self.type ||= self.imap_provider.partner_connection_class.to_s
  end

  # Public: Used by ActiveAdmin.
  def display_name
    self.imap_provider_code
  end

  def imap_provider_code
    self.imap_provider.code
  end

  # Public: Create a new user that bases it's type on the
  # PartnerConnection type. In other words, if this is an
  # Oauth1::PartnerConnection, then return an Oauth1::User.
  def new_typed_user
    user = self.imap_provider.user_class.new
    self.users << user
    user
  end
end
