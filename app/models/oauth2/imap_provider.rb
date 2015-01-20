require 'xoauth2_authenticator'

class Oauth2::ImapProvider < ImapProvider
  include ConnectionFields

  connection_field :oauth2_grant_type, :required => true
  connection_field :oauth2_scope, :required => true
  connection_field :oauth2_site, :required => true
  connection_field :oauth2_token_method, :required => true
  connection_field :oauth2_token_url, :required => true
  connection_field :oauth2_authorize_url, :required => true
  connection_field :oauth2_response_type, :required => true
  connection_field :oauth2_access_type, :required => true
  connection_field :oauth2_approval_prompt, :required => true

  def authenticate_imap(client, user)
    client.authenticate('XOAUTH2', user.email, _access_token(user))
  end

  def authenticate_smtp(mail, user)
    mail.delivery_method.settings.merge!(
      :address              => smtp_host,
      :port                 => smtp_port,
      :domain               => smtp_domain,
      :user_name            => user.email,
      :password             => _access_token(user),
      :authentication       => :xoauth2,
      :enable_starttls_auto => smtp_enable_starttls_auto
    )
  end

  private

  def _access_token(user)
    partner_connection = user.partner_connection

    oauth_client = OAuth2::Client.new(
      partner_connection.oauth2_client_id,
      partner_connection.oauth2_client_secret_secure,
      {
        :site         => oauth2_site,
        :token_url    => oauth2_token_url,
        :token_method => oauth2_token_method.to_sym,
        :grant_type   => oauth2_grant_type,
        :scope        => oauth2_scope
      })

    oauth2_access_token = oauth_client.get_token(
      {
        :client_id     => partner_connection.oauth2_client_id,
        :client_secret => partner_connection.oauth2_client_secret_secure,
        :refresh_token => user.oauth2_refresh_token_secure,
        :grant_type    => oauth2_grant_type
      })

    oauth2_access_token.token
  end
end
