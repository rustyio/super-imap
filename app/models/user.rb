class User < ActiveRecord::Base
  include ConnectionFields

  # Magic.
  before_validation :fix_type

  # Scopes.
  scope :active, proc { where(:archived => false) }
  scope :archived, proc { where(:archived => true) }

  # Relations.
  has_many :mail_logs, :dependent => :destroy
  belongs_to :partner_connection, :counter_cache => true
  alias_method :connection, :partner_connection

  # Validations.
  validates_presence_of :tag
  validates_uniqueness_of :tag, :case_sensitive => false,
                          :scope => :partner_connection_id,
                          :conditions => -> { where.not(archived: true) }

  validates_presence_of :email
  validates_uniqueness_of :email, :case_sensitive => false,
                          :scope => :partner_connection_id,
                          :conditions => -> { where.not(archived: true) }

  def imap_provider
    self.connection.imap_provider
  end

  # Public: Calculate a timestamped signature. Used to sign redirect
  # URLs. Returns a hash.
  def signed_request_params(timestamp = nil)
    timestamp ||= Time.now.to_i
    data = "#{self.id} - #{timestamp} - #{self.connection.partner.api_key}"
    {
      :user_id => id,
      :ts      => timestamp,
      :sig     => Digest::SHA1.hexdigest(data).slice(0, 10)
    }
  end

  # Public: Verify a timestamp signature.
  def valid_signature?(params)
    (Time.at(params[:ts].to_i) > 30.minutes.ago) &&
      params[:sig] == signed_request_params(params[:ts])[:sig]
  end

  private

  # Private: Automatically set the STI type based on the imap_provider.
  def fix_type
    self.type ||= self.partner_connection.imap_provider.class_for(User).to_s
  end
end
