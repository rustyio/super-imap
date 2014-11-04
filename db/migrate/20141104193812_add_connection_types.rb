class AddConnectionTypes < ActiveRecord::Migration
  def up
    ConnectionType.create(
      :identifier => 'GREENMAIL',
      :title      => "Greenmail - Fake IMAP",
      :host       => "localhost",
      :port       => 10143,
      :use_ssl    => false)

    ConnectionType.create(
      :identifier                => 'GMAIL_OAUTH_1',
      :title                     => "Google Mail - OAuth 1.0",
      :host                      => "imap.gmail.com",
      :port                      => 993,
      :use_ssl                   => true,
      :oauth1_scope              => "https://www.googleapis.com/auth/userinfo.email https://mail.google.com/",
      :oauth1_site               => "https://www.google.com",
      :oauth1_request_token_path => "/accounts/OAuthGetRequestToken",
      :oauth1_authorize_path     => "/accounts/OAuthAuthorizeToken",
      :oauth1_access_token_path  => "/accounts/OAuthGetAccessToken")

    ConnectionType.create(
      :identifier          => 'GMAIL_OAUTH_2',
      :title               => "Google Mail - OAuth 2.0",
      :host                => "imap.gmail.com",
      :port                => 993,
      :use_ssl             => true,
      :oauth2_site         => "https://accounts.google.com",
      :oauth2_token_url    => "/o/oauth2/token",
      :oauth2_token_method => "post",
      :oauth2_grant_type   => "refresh_token",
      :oauth2_scope        => "https://www.googleapis.com/auth/userinfo.email https://mail.google.com/")
  end
end
