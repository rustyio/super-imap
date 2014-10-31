class Partner < ActiveRecord::Base
  # Magic.
  strip_attributes
  before_save :ensure_api_key

  # Relations
  has_many :partner_connections, :dependent => :destroy
  alias_method :connections, :partner_connections

  # Validations
  validates :name, :presence => true

  def ensure_api_key
    self.api_key ||= SecureRandom.hex(10)
  end
end
