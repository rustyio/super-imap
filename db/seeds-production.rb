Oauth1::ImapProvider.create!(
  :code                      => 'GMAIL_OAUTH1',
  :title                     => "Google Mail - OAuth 1.0",
  :host                      => "imap.gmail.com",
  :port                      => 993,
  :use_ssl                   => true,
  :oauth1_scope              => "https://www.googleapis.com/auth/userinfo.email https://mail.google.com/",
  :oauth1_site               => "https://www.google.com",
  :oauth1_request_token_path => "/accounts/OAuthGetRequestToken",
  :oauth1_authorize_path     => "/accounts/OAuthAuthorizeToken",
  :oauth1_access_token_path  => "/accounts/OAuthGetAccessToken")

Oauth2::ImapProvider.create!(
  :code                   => 'GMAIL_OAUTH2',
  :title                  => "Google Mail - OAuth 2.0",
  :host                   => "imap.gmail.com",
  :port                   => 993,
  :use_ssl                => true,
  :oauth2_site            => "https://accounts.google.com",
  :oauth2_token_url       => "/o/oauth2/token",
  :oauth2_token_method    => "post",
  :oauth2_grant_type      => "refresh_token",
  :oauth2_scope           => "https://www.googleapis.com/auth/userinfo.email https://mail.google.com/",
  :oauth2_token_url       => "/o/oauth2/token",
  :oauth2_authorize_url   => "/o/oauth2/auth",
  :oauth2_response_type   => "code",
  :oauth2_access_type     => "offline",
  :oauth2_approval_prompt => "force")

AdminUser.new(:email => "admin@example.com", :password => "password").save
