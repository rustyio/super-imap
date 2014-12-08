require 'timeout'
require 'net/imap'

class BaseWebhook
  private unless Rails.env.test?

  def calculate_signature(api_key, uid, timestamp)
    digest = OpenSSL::Digest.new('sha256')
    return OpenSSL::HMAC.hexdigest(digest, api_key, "#{timestamp}#{uid}")
  end
end
