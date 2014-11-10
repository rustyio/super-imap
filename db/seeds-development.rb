AdminUser.new(:email => "admin@example.com", :password => "password").save

conn_type = ConnectionType.create(
  :identifier => 'LOCALHOST',
  :title      => "Fake IMAP",
  :host       => "localhost",
  :port       => 10143,
  :use_ssl    => false)

def create_transmit_log(mail_log, n)
  mail_log.transmit_logs.create(:response_code => 200, :response_body => "Response #{n}")
end

def create_mail_log(user, n)
  user.mail_logs.create(:message_id => "abc#{n}").tap do |mail_log|
    create_transmit_log(mail_log, 1)
    create_transmit_log(mail_log, 2)
    create_transmit_log(mail_log, 3)
  end
end

def create_user(connection, n)
  connection.users.create(
    :tag            => "User #{n}",
    :email          => "user#{n}@localhost",
    :login_username => "user#{n}@localhost",
    :login_password => "password").tap do |user|
    create_mail_log(user, 1)
    create_mail_log(user, 2)
    create_mail_log(user, 3)
  end
end

def create_partner_connection(partner, ct)
  partner.connections.create(:connection_type_id => ct.id).tap do |connection|
    5.times.each do |n|
      create_user(connection, n)
    end
  end
end

Partner.create(:name => "Partner").tap do |partner|
  create_partner_connection(partner, conn_type)
end
