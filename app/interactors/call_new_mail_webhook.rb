# encoding: utf-8

class CallNewMailWebhook < BaseWebhook
  attr_accessor :mail_log, :envelope, :raw_eml

  def initialize(mail_log, envelope, raw_eml)
    self.mail_log = mail_log
    self.envelope = envelope
    self.raw_eml = raw_eml
  end

  def run
    user = mail_log.user
    partner = user.partner_connection.partner

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

    # START DEBUGGING!
    begin
      envelope.to_json
    rescue => e
      Log.info("Problem converting to JSON:\n#{envelope}.")
    end

    begin
      raw_eml.to_json
    rescue => e
      Log.info("Problem converting to JSON:\n#{raw_eml}.")
    end
    # END DEBUGGING!

    # Post the data
    begin
      transmit_log = mail_log.transmit_logs.create()

      # Post the data.
      webhook = RestClient::Resource.new(partner.new_mail_webhook)
      response = Timeout::timeout(30) do
        webhook.post(data.to_json, :content_type => :json, :accept => :json)
      end

      # Update the transmit log record.
      transmit_log.update_attributes!(:response_code => response.code.to_i,
                                      :response_body => response.to_s.slice(0, 1024))

      Log.librato(:count, 'app.call_new_mail_webhook.count', 1)
      return true
    rescue RestClient::Forbidden => e
      response = e.response
      transmit_log.update_attributes!(:response_code => response.code.to_i,
                                      :response_body => response.to_s.slice(0, 1024))

      # The server understood the request but refused it. Mark the
      # user as archived, but only if it's not a tracer user.
      if !user.enable_tracer
        user.update_attributes!(:archived => true)
      end
    rescue RestClient::Exception => e
      response = e.response
      transmit_log.update_attributes!(:response_code => response.code.to_i,
                                      :response_body => response.to_s.slice(0, 1024))
      raise e
    rescue => e
      transmit_log.update_attributes!(:response_code => "ERROR",
                                      :response_body => e.to_s.slice(0, 1024))
      raise e
    end
  end
end
