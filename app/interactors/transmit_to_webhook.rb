require 'timeout'

class TransmitToWebhook
  attr_accessor :mail_log, :envelope, :raw_eml

  def initialize(mail_log, envelope, raw_eml)
    self.mail_log = mail_log
    self.envelope = envelope
    self.raw_eml = raw_eml
  end

  def run
    partner = mail_log.user.partner_connection.partner

    # Assemble the payload.
    data = {
      :timestamp => Time.now.to_i,
      :sha1      => mail_log.sha1,
      :user_tag  => user.tag,
      :envelope  => envelope,
      :rfc822    => raw_eml
    }
    data[:signature] = calculate_signature(partner.api_key, data[:sha1], data[:timestamp])

    # Post the data
    begin
      transmit_log = mail_log.transmit_logs.create()

      # Post the data.
      webhook = RestClient::Resource.new(partner.success_webhook)
      response = Timeout::timeout(30) do
        webhook.post(data.to_json, :content_type => :json, :accept => :json)
      end

      # Update the transmit log record.
      transmit_log.update_attributes(:response_code => response.code.to_i,
                                     :response_body => response.to_s.slice(0, 1024))

      # Check the error code.
      code = response.code.to_i
      if ![200, 201, 202, 204].include?(code)
        # We didn't see one of the expected response codes, so raise
        # an error, which will try again.
        raise FailedWebhookError.new("Failed webhook #{code} - #{response.to_s}")
      end
    rescue RestClient::Exception => e
      transmit_log.update_attributes(:response_code => e.response.code,
                                     :response_body => "#{e.to_s} #{e.response.to_s}".slice(0, 1024))
      raise e
    end
  end

  def calculate_signature(api_key, uid, timestamp)
    digest = OpenSSL::Digest.new('sha256')
    return OpenSSL::HMAC.hexdigest(digest, api_key, "#{timestamp}#{uid}")
  end
end
