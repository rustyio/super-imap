class PartnerConnection < ActiveRecord::Base
  belongs_to :partner, :counter_cache => true
  belongs_to :connection_type, :counter_cache => true
  has_many :users, :dependent => :destroy

  def users
    # Convert 'Connection::Plain' to 'User::Plain'.
    user_type =  self.connection_type.type.gsub("Connection::", "User::")
    User.where(:partner_connection_id => self.id, :type => user_type)
  end
end
