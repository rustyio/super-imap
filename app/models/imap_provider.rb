class ImapProvider < ActiveRecord::Base
  include ConnectionFields
  has_many :partner_connections

  def display_name
    self.code
  end

  # Public: Single Table Inheritance helper. Returns the correct
  # inherited class depending on the ImapProvider class.
  #
  # Usage:
  #
  #     imap_provider = Oauth2::ImapProvider.new
  #     imap_provider.class_for(User) => Oauth2::User
  #
  # Returns a class.
  def class_for(c)
    (self.class.parent_name + "::" + c.base_class.name).constantize
  end

  # Public: Single Table Inheritance helper. Returns the name of a
  # helper method depending on the ImapProvider class.
  #
  # Usage:
  #
  #     imap_provider = Oauth2::ImapProvider.new
  #     imap_provider.helper_for(:connects, :new) => :oauth2_new_connects_helper
  #
  # Returns a symbol.
  def helper_for(action)
    "#{self.class.parent_name.underscore}_#{action}_helper".to_sym
  end
end
