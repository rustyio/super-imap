class MailLog < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  has_many :transmit_logs, :dependent => :destroy
end
