class User < ActiveRecord::Base
  belongs_to :partner_connection, :counter_cache => true
  has_many :mail_logs, :dependent => :destroy
  alias_method :connection, :partner_connection

  validates_presence_of :email
  validates_uniqueness_of :email, :case_sensitive => false,
                          :scope => :partner_connection_id,
                          :conditions => -> { where.not(archived: true) }
end
