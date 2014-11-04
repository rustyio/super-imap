class User < ActiveRecord::Base
  belongs_to :partner_connection, :counter_cache => true
  has_many :mail_logs, :dependent => :destroy
  alias_method :connection, :partner_connection
end
