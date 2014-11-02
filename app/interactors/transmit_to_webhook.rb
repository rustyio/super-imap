require 'timeout'

class TransmitToWebhook
  attr_accessor :mail_log, :raw_eml

  def initialize(mail_log, envelope, raw_eml)
    self.mail_log = mail_log
    self.raw_eml = raw_eml
  end

  def run
    partner = mail_log.user.partner_connection.partner

    # Assemble the payload.
    data = {
      :md5      => mail_log.md5,
      :timestamp => Time.now.to_i,
      :user_tag => user.tag,
      :envelope => envelope,
      :rfc822   => raw_eml
    }
    data[:signature] = calculate_signature(partner.api_key, data[:md5], data[:timestamp])

    # Begin the transmit log.

    # Post the data
    begin
      transmit_log = mail_log.transmit_logs.create()
      webhook = RestClient::Resource.new(partner.success_webhook)
      response = Timeout::timeout(30) do
        webhook.post(data.to_json, :content_type => :json, :accept => :json)
      end
      transmit_log.code = response.code
      transmit_log.response = response.to_s.slice(0, 1024)
      transmit_log.save

      code = response.code.to_s
      if ["200", "201", "202", "204"].include?(code)
        # Success.
        return true
      elsif ["403"].include?(code)
        # The webhook understood the request but refused to accept it,
        # most likely because the recipient has disabled the lead
        # source in question. Try to relay the email to the intended
        # recipient.
        job = System::RelayMailLog.new(@mail_log)
        job.delay.run
        return false
      else
        # We didn't see one of the expected response codes, so raise
        # an error, which will try again.
        raise FailedWebhookError.new("Failed webhook #{code} - #{response.to_s}")
      end
    rescue RestClient::Exception => e
      # TODO - Figure out a way to generate this exception so we can test it.
      transmit_log.response = "#{e.to_s} #{e.response.to_s}"
      transmit_log.save
      raise e
    rescue StandardError => e
      transmit_log.code = "ERROR"
      transmit_log.response = e.to_s
      transmit_log.save
      raise e
    end

  end

  def calculate_signature(api_key, uid, timestamp)
    digest = OpenSSL::Digest.new('sha256')
    return OpenSSL::HMAC.hexdigest(digest, api_key, "#{timestamp}#{uid}")
  end
end
