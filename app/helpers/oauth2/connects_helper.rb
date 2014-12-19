module Oauth2::ConnectsHelper
  BadRequestError = Class.new(StandardError)

  attr_accessor :oauth2_token

  def oauth2_new_helper
    # Construct the client.
    client = OAuth2::Client.new(
      connection.oauth2_client_id_secure,
      connection.oauth2_client_secret_secure,
      :site          => imap_provider.oauth2_site,
      :authorize_url => imap_provider.oauth2_authorize_url)

    # Construct the auth url.
    auth_url = client.auth_code.authorize_url(
      :redirect_uri    => callback_users_connect_url(),
      :response_type   => imap_provider.oauth2_response_type,
      :state           => "",
      :scope           => imap_provider.oauth2_scope,
      :access_type     => imap_provider.oauth2_access_type,
      :approval_prompt => imap_provider.oauth2_approval_prompt)

    # Redirect.
    redirect_to auth_url
  end

  def oauth2_callback_helper
    # Exchange the code for a refresh token.
    # https://developers.google.com/accounts/docs/OAuth2WebServer
    client = OAuth2::Client.new(
      connection.oauth2_client_id_secure,
      connection.oauth2_client_secret_secure,
      :site        => imap_provider.oauth2_site,
      :token_url   => imap_provider.oauth2_token_url)

    self.oauth2_token = client.auth_code.get_token(
      params[:code],
      :redirect_uri => callback_users_connect_url())

    user.update_attributes!(
      :email                => oauth2_email,
      :oauth2_refresh_token => oauth2_token.refresh_token,
      :connected_at         => Time.now)

    begin
      CallUserConnectedWebhook.new(user).run
    rescue => e
      CallUserConnectedWebhook.new(user).delay.run
    end

    redirect_to_success_url
  rescue => e
    Log.exception(e)
    redirect_to_failure_url
  end

  def oauth2_email
    method = "#{imap_provider.code.downcase}_email".to_sym
    send(method)
  end

  def gmail_oauth2_email
    # Get the google email address.
    data = JSON.parse(oauth2_token.get("https://www.googleapis.com/userinfo/email?alt=json").body)
    return data["data"]["email"]
  end
end
