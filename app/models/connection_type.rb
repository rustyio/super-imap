class ImapProvider < ActiveRecord::Base
  has_many :partner_connections

  def display_name
    self.code
  end

  def self.connection_fields
    []
  end

  def connection_fields
    self.class.connection_fields
  end
end
