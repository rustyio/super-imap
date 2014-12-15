Oauth2::ImapProvider.create!(
  :code                      => 'GMAIL_OAUTH2',
  :title                     => "Google Mail - OAuth 2.0",
  :imap_host                 => "imap.gmail.com",
  :imap_port                 => 993,
  :imap_use_ssl              => true,
  :smtp_host                 => "smtp.gmail.com",
  :smtp_port                 => 587,
  :smtp_domain               => "gmail.com",
  :smtp_enable_starttls_auto => true,
  :oauth2_site               => "https://accounts.google.com",
  :oauth2_token_url          => "/o/oauth2/token",
  :oauth2_token_method       => "post",
  :oauth2_grant_type         => "refresh_token",
  :oauth2_scope              => "https://www.googleapis.com/auth/userinfo.email https://mail.google.com/",
  :oauth2_token_url          => "/o/oauth2/token",
  :oauth2_authorize_url      => "/o/oauth2/auth",
  :oauth2_response_type      => "code",
  :oauth2_access_type        => "offline",
  :oauth2_approval_prompt    => "force")

AdminUser.new(:email => "admin@example.com", :password => "password").save
