class PartnerConnection < ActiveRecord::Base
  include ConnectionFields

  belongs_to :partner, :counter_cache => true
  belongs_to :imap_provider, :counter_cache => true
  has_many :users, :dependent => :destroy

  validates_presence_of :imap_provider_id
  validates_uniqueness_of :imap_provider_id, :scope => :partner_id
  before_validation :fix_type

  def fix_type
    new_type = self.imap_provider.type.gsub("::ImapProvider", "::PartnerConnection")
    self.type = new_type
  end

  # Public: Used by ActiveAdmin.
  def display_name
    self.imap_provider_code
  end

  def imap_provider_code
    self.imap_provider.code
  end
end
