class CallUserConnectedWebhook < BaseWebhook
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def run
    partner = user.partner_connection.partner

    if partner.user_connected_webhook.blank?
      return false
    end

    # Assemble the payload.
    data = {
      :timestamp          => Time.now.to_i,
      :sha1               => Digest::SHA1.hexdigest(user.tag),
      :user_tag           => user.tag,
      :imap_provider_code => user.connection.imap_provider_code,
      :email              => user.email
    }
    data[:signature] = calculate_signature(partner.api_key, data[:sha1], data[:timestamp])

    # Post the data.
    begin
      webhook = RestClient::Resource.new(partner.user_connected_webhook)
      response = Timeout::timeout(30) do
        webhook.post(data.to_json, :content_type => :json, :accept => :json)
      end
      Log.librato(:count, 'app.call_user_connected_webhook.count', 1)
    rescue RestClient::Forbidden => e
      # The server understood the request but refused it. Mark the
      # user as archived, but only if it's not a tracer user.
      if !user.enable_tracer
        user.update_attributes!(:archived => true)
      end
    end
  end
end
