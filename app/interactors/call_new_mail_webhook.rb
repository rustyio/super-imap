require 'timeout'

class CallNewMailWebhook < BaseWebhook
  attr_accessor :mail_log, :envelope, :raw_eml

  def initialize(mail_log, envelope, raw_eml)
    self.mail_log = mail_log
    self.envelope = envelope
    self.raw_eml = raw_eml
  end

  def run
    partner = mail_log.user.partner_connection.partner

    if partner.new_mail_webhook.blank?
      return false
    end

    # Assemble the payload.
    data = {
      :timestamp          => Time.now.to_i,
      :sha1               => mail_log.sha1,
      :user_tag           => user.tag,
      :imap_provider_code => user.connection.imap_provider_code,
      :envelope           => envelope,
      :rfc822             => raw_eml
    }
    data[:signature] = calculate_signature(partner.api_key, data[:sha1], data[:timestamp])

    # Post the data
    begin
      transmit_log = mail_log.transmit_logs.create()

      # Post the data.
      webhook = RestClient::Resource.new(partner.new_mail_webhook)
      response = Timeout::timeout(30) do
        webhook.post(data.to_json, :content_type => :json, :accept => :json)
      end

      # Update the transmit log record.
      transmit_log.update_attributes(:response_code => response.code.to_i,
                                     :response_body => response.to_s.slice(0, 1024))

      return true
    rescue RestClient::Exception => e
      # Received some kind of failure response code. Log it.
      response = e.response
      transmit_log.update_attributes(:response_code => response.code.to_i,
                                     :response_body => response.to_s.slice(0, 1024))

      if response.code == 403
        # The server understood the request but refused it. Mark the
        # user as archived.
        user.update_attributes!(:archived => true)
        return false
      else
        raise e
      end
    rescue => e
      transmit_log.update_attributes(:response_code => "ERROR"
                                     :response_body => e.to_s.slice(0, 1024))
      raise e
    end
  end
end
