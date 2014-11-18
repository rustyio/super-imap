class ImapProvider < ActiveRecord::Base
  include ConnectionFields
  has_many :partner_connections

  def display_name
    self.code
  end

  def partner_connection_class
    raise "Must override #partner_connection_class in #{self.class.to_s}."
  end

  def user_class
    raise "Must override #user_class in #{self.class.to_s}."
  end
end
