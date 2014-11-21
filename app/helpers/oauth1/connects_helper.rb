module Oauth1::ConnectsHelper
  def oauth1_load_user
  end

  def oauth1_validate_signature
  end

  def oauth1_new_helper
    consumer = OAuth::Consumer.new(
      connection.oauth1_consumer_key,
      connection.oauth1_consumer_secret,
      :site               => imap_provider.oauth1_site,
      :request_token_path => imap_provider.oauth1_request_token_path,
      :authorize_path     => imap_provider.oauth1_authorize_path,
      :access_token_path  => imap_provider.oauth1_access_token_path)

    callback = "#{https}://#{hostname}/oauth/gmail_response"
    request_token = consumer.get_request_token(
      {:oauth_callback => callback },
      {:scope => "https://www.googleapis.com/auth/userinfo.email https://mail.google.com/"}
    )

  end

  def oauth1_callback_helper
  end
end
