class EncryptExistingData < ActiveRecord::Migration
  def up
    # Update Oauth2::PartnerConnection entries.
    connections = PartnerConnection.where(:type => "Oauth2::PartnerConnection")
    connections.each do |connection|
      connection.oauth2_client_secret = connection.oauth2_client_secret_secure
      connection.save!
    end

    # Update Oauth2::User entries.
    users = User.where(:type => "Oauth2::User")
    users.each_index do |index|
      user = users[index]
      print "(#{index + 1}/#{users.length}) #{user.email}\n"
      user.oauth2_refresh_token = user.oauth2_refresh_token_secure
      user.save!
    end

    # Update Plain::User entries.
    users = User.where(:type => "Plain::User")
    users.each_index do |index|
      user = users[index]
      print "(#{index + 1}/#{users.length}) #{user.email}\n"
      user.login_password = user.login_password_secure
      user.save!
    end
  end

  def down
  end
end
