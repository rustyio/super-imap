class CallUserConnectedWebhook < BaseWebhook
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def run
    partner = mail_log.user.partner_connection.partner

    # Assemble the payload.
    data = {
      :timestamp          => Time.now.to_i,
      :sha1               => Digest::SHA1.hexdigest(user.tag)
      :user_tag           => user.tag,
      :imap_provider_code => user.connection.imap_provider_code
    }
    data[:signature] = calculate_signature(partner.api_key, data[:sha1], data[:timestamp])

    # Post the data.
    webhook = RestClient::Resource.new(partner.user_disconnected_webhook)
    response = Timeout::timeout(30) do
      webhook.post(data.to_json, :content_type => :json, :accept => :json)
    end
  end
end
