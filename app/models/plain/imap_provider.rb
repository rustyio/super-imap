class Plain::ImapProvider < ImapProvider
  include ConnectionFields

  def authenticate_smtp(mail, user)
    mail.delivery_method.settings.merge!(
      :address              => smtp_host,
      :port                 => smtp_port,
      :domain               => smtp_domain,
      :user_name            => user.login_username,
      :password             => user.login_password,
      :authentication       => :plain,
      :enable_starttls_auto => enable_starttls_auto
    )

    client.login(user.login_username, user.login_password_secure)
  end

  def authenticate_imap(client, user)
    client.login(user.login_username, user.login_password_secure)
  end
end
