module Oauth1::ConnectsHelper
  attr_accessor :oauth1_access_token

  def oauth1_new_helper
    consumer = OAuth::Consumer.new(
      connection.oauth1_consumer_key_secure,
      connection.oauth1_consumer_secret_secure,
      :site               => imap_provider.oauth1_site,
      :request_token_path => imap_provider.oauth1_request_token_path,
      :authorize_path     => imap_provider.oauth1_authorize_path,
      :access_token_path  => imap_provider.oauth1_access_token_path)

    request_token = consumer.get_request_token(
      {:oauth_callback => callback_users_connect_url() },
      {:scope => imap_provider.oauth1_scope })

    session[:oauth1_request_token] = Marshal.dump(request_token)

    redirect_to request_token.authorize_url
  end

  def oauth1_callback_helper
    request_token  = Marshal.load(session[:oauth1_request_token])
    self.oauth1_access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])

    self.user.update_attributes!(
      :email               => oauth1_email,
      :oauth1_token        => oauth1_access_token.params[:oauth_token],
      :oauth1_token_secret => oauth1_access_token.params[:oauth_token_secret],
      :connected_at        => Time.now)

    redirect_to_success_url
  rescue => e
    Log.exception(e)
    redirect_to_failure_url
  end

  def oauth1_email
    method = "#{imap_provider.code.downcase}_email".to_sym
    send(method)
  end

  def gmail_oauth1_email
    # Get the google email address.
    data = JSON.parse(self.oauth1_access_token.get("https://www.googleapis.com/userinfo/email?alt=json").body)
    return data["data"]["email"]
  end
end
