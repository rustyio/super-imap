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

    # Fix improper encodings enough to satisfy JSON.dump.
    # TODO - The sha1 changed; re-check for duplicates?
    begin
      JSON.dump(raw_eml)
    rescue => e
      self.raw_eml = fix_encoding(raw_eml)
      sha1 = Digest::SHA1.hexdigest(raw_eml)
      mail_log.update_attributes(:sha1 => sha1)
    end

    # Assemble the payload. We use the Mail class to decode and then
    # re-encode the raw_eml to fix any potential character encoding
    # issues.
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
      Log.debug("Problem converting to JSON:\n#{envelope}.")
    end

    begin
      raw_eml.to_json
    rescue => e
      Log.debug("Problem converting to JSON:\n#{raw_eml}.")
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

  private

  # Private: Fix mail encoding. Some emails contain escaped characters
  # that are not valid in the encoding that the claim to be using.
  def fix_encoding(raw_eml)
    m = Mail.new(raw_eml)

    m.body = fix_body_encoding(m.body, m.charset)

    m.parts.each do |part|
      part.body = fix_body_encoding(part.body, part.charset)
    end if m.parts

    m.encoded
  rescue => e
    Log.exception(e)
    raw_eml.force_encoding('UTF-8').scrub
  end

  def fix_body_encoding(body, charset)
    # Force the part body to use the charset it claims to use. Then
    # remove invalid characters for that charset.
    body && body.decoded.force_encoding(charset || 'UTF-8').scrub
  rescue => e
    body && body.decoded.force_encoding('UTF-8').scrub
  end
end
