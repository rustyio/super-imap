require 'oauth'
require 'oauth2'

class IMAP::Authenticator
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def authenticate(client)
    identifier = user.connection.connection_type.identifier
    method = "authenticate_#{identifier.downcase}".to_sym
    return self.send(:method, client)
  end

  private unless Rails.env.test?

  # Private: Connect to greenmail, used for performance testing.
  def authenticate_greenmail
    authenticate_login
  end

  # Private: Connect to Gmail using OAUTH 1.0.
  def authenticate_gmail_oauth_1
    return authenticate_oauth_1
  end

  # Private: Connect to Gmail using OAUTH 2.0.
  def authenticate_gmail_oauth_2
    return authenticate_oauth_2
  end

  ###
  # Generic authentication methods.
  ###

  # Private: Connect via username and password.
  def authenticate_login
    client.authenticate('LOGIN', user.login_username, user.login_password)
  end

  # Private: Connect via OAUTH 1.0
  def authenticate_oauth_1
    conn  = user.connection
    conn_type = conn.connection_type

    consumer = OAuth::Consumer.new(
      conn.oauth1_consumer_key,
      conn.oauth1_consumer_secret,
      "site"               => conn_type.oauth1_site,
      "request_token_path" => conn_type.oauth1_request_token_path,
      "authorize_path"     => conn_type.oauth1_authize_path,
      "access_token_path"  => conn_type.oauth1_access_token_path)

    access_token = OAuth::AccessToken.new(consumer,
                                          user.oauth1_token,
                                          user.oauth1_token_secret)

    client.authenticate('XOAUTH', user.email, :access_token => access_token)
  end

  # Private: Connect via OAUTH 2.0
  def authenticate_oauth_2
    conn = user.connection
    conn_type = conn.connection_type

    oauth_client = OAuth2::Client.new(
      conn.oauth2_client_id,
      conn.oauth2_client_secret,
      "site"         => conn_type.oauth2_site,
      "token_url"    => conn_type.oauth2_token_url,
      "token_method" => conn_type.oauth2_token_method,
      "grant_type"   => conn_type.oauth2_grant_type,
      "scope"        => conn_type.oauth2_scope)

    oauth2_access_token = client.get_token(
      "client_id"     => conn.oauth2_client_id,
      "client_secret" => conn.oauth2_client_secret,
      "refresh_token" => user.oauth2_refresh_token,
      "grant_type"    => conn_type.oauth2_grant_type)

    client.authenticate('XOAUTH2', user.email, oauth2_access_token.token)
  end
end
