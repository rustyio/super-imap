class PartnerConnection < ActiveRecord::Base
  belongs_to :partner, :counter_cache => true
  belongs_to :connection_type, :counter_cache => true
  has_many :users, :dependent => :destroy

  validates_uniqueness_of :connection_type_id, :scope => :partner_id

  # Public: Used by ActiveAdmin.
  def display_name
    self.auth_mechanism
  end

  def users
    # Convert 'Connection::Plain' to 'User::Plain'.
    user_type =  self.connection_type.type.gsub("Connection::", "User::")
    User.where(:partner_connection_id => self.id, :type => user_type)
  end

  def auth_mechanism
    self.connection_type.auth_mechanism
  end

  def self.where_auth_mechanism(auth_mechanism)
    conn_type = ConnectionType.find_by_auth_mechanism(auth_mechanism)
    where(:connection_type_id => conn_type.id)
  end
end
