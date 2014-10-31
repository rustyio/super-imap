class PartnerConnection < ActiveRecord::Base
  belongs_to :partner, :counter_cache => true
  belongs_to :connection_type, :counter_cache => true
  has_many :users, :dependent => :destroy

  def display_name
    connection_type.identifier
  end
end
