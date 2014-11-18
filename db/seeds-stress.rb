AdminUser.new(:email => "admin@example.com", :password => "password").save

conn_type = ImapProvider.create(
  :code => 'SIMPLE',
  :title          => "Fake IMAP",
  :host           => "localhost",
  :port           => 10143,
  :use_ssl        => false)

def create_user(connection, n)
  connection.users.create(
    :tag            => "User #{n}",
    :email          => "user#{n}@localhost",
    :login_username => "user#{n}@localhost",
    :login_password => "password")
end

def create_partner_connection(partner, ct)
  partner.connections.create(:imap_provider_id => ct.id).tap do |connection|
    1000.times.each do |n|
      create_user(connection, n)
    end
  end
end

Partner.create(:name => "Partner").tap do |partner|
  create_partner_connection(partner, conn_type)
end
