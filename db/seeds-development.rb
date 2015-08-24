AdminUser.new(:email => "admin@example.com", :password => "password").save

plain_provider = Plain::ImapProvider.create(
  :code         => 'PLAIN',
  :title        => "Fake IMAP",
  :imap_host    => "localhost",
  :imap_port    => 10143,
  :imap_use_ssl => false)

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
  :oauth2_token_method       => "post",
  :oauth2_grant_type         => "refresh_token",
  :oauth2_scope              => "https://www.googleapis.com/auth/userinfo.email https://mail.google.com/",
  :oauth2_token_url          => "/o/oauth2/token",
  :oauth2_authorize_url      => "/o/oauth2/auth",
  :oauth2_response_type      => "code",
  :oauth2_access_type        => "offline",
  :oauth2_approval_prompt    => "force")

def create_transmit_log(mail_log, n)
  mail_log.transmit_logs.create(:response_code => 200, :response_body => "Response #{n}")
end

def create_mail_log(user, n)
  user.mail_logs.create!(:message_id => "abc#{n}").tap do |mail_log|
    create_transmit_log(mail_log, 1)
    create_transmit_log(mail_log, 2)
    create_transmit_log(mail_log, 3)
  end
end

def create_user(connection, n)
  connection.users.create!(
    :tag            => "User #{n}",
    :email          => "user#{n}@localhost",
    :login_username => "user#{n}@localhost",
    :login_password => "password").tap do |user|
    create_mail_log(user, 1)
    create_mail_log(user, 2)
    create_mail_log(user, 3)
  end
end

def create_partner_connection(partner, imap_provider)
  partner.connections.create!(:imap_provider_id => imap_provider.id).tap do |connection|
    5.times.each do |n|
      create_user(connection, n)
    end
  end
end

Partner.create!(
  :name                      => "Partner",
  :new_mail_webhook          => "http://localhost:5000/webhook_test/new_mail",
  :user_connected_webhook    => "http://localhost:5000/webhook_test/user_connected",
  :user_disconnected_webhook => "http://localhost:5000/webhook_test/user_disconnected",
  :success_url               => "/success.html",
  :failure_url               => "/failure.html").tap do |partner|
  create_partner_connection(partner, plain_provider)
end
