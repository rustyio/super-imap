class User::Plain < User
  def self.connection_fields
    [:login_username, :login_password]
  end
end
