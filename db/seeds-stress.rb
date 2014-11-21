AdminUser.new(:email => "admin@example.com", :password => "password").save

imap_provider = Plain::ImapProvider.create!(
  :code    => 'PLAIN',
  :title   => "Fake IMAP",
  :host    => "localhost",
  :port    => 10143,
  :use_ssl => false)

def create_user(connection, n)
  connection.users.create!(
    :tag            => "User #{n}",
    :email          => "user#{n}@localhost",
    :login_username => "user#{n}@localhost",
    :login_password => "password")
end

def create_partner_connection(partner, imap_provider)
  partner.connections.create!(:imap_provider_id => imap_provider.id).tap do |connection|
    1000.times.each do |n|
      create_user(connection, n)
    end
  end
end

Partner.create!(
  :name            => "Partner",
  :success_webhook => "ignored",
  :failure_webhook => "ignored",
  :success_url     => "ignored",
  :failure_url     => "ignored").tap do |partner|
  create_partner_connection(partner, imap_provider)
end
