class User < ActiveRecord::Base
  has_many :mail_logs, :dependent => :destroy
  belongs_to :partner_connection, :counter_cache => true
  alias_method :connection, :partner_connection

  validates_presence_of :tag
  validates_uniqueness_of :tag, :case_sensitive => false,
                          :scope => :partner_connection_id,
                          :conditions => -> { where.not(archived: true) }

  validates_presence_of :email
  validates_uniqueness_of :email, :case_sensitive => false,
                          :scope => :partner_connection_id,
                          :conditions => -> { where.not(archived: true) }

  scope :active, proc { where(:archived => false) }
  scope :archived, proc { where(:archived => true) }

  def self.connection_fields
    []
  end

  def connection_fields
    self.class.connection_fields
  end
end
