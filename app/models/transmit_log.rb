class TransmitLog < ActiveRecord::Base
  belongs_to :mail_log, :counter_cache => true
end
