class ImapProvider < ActiveRecord::Base
  include ConnectionFields
  has_many :partner_connections

  def display_name
    self.code
  end
end
