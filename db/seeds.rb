AdminUser.new(:email => "rusty@fivestreet.com", :password => "password").save

ct1 = ConnectionType.create(:identifier => "TYPE 1")
ct2 = ConnectionType.create(:identifier => "TYPE 2")
ct3 = ConnectionType.create(:identifier => "TYPE 3")

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
  connection.users.create(:email => "email#{n}@email.com", :tag => "User #{n}").tap do |user|
    create_mail_log(user, 1)
    create_mail_log(user, 2)
    create_mail_log(user, 3)
  end
end

def create_partner_connection(partner, ct)
  partner.connections.create(:connection_type_id => ct.id).tap do |connection|
    create_user(connection, 1)
    create_user(connection, 2)
    create_user(connection, 3)
  end
end

Partner.create(:name => "Partner").tap do |partner|
  create_partner_connection(partner, ct1)
  create_partner_connection(partner, ct2)
  create_partner_connection(partner, ct3)
end
