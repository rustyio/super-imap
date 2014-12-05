class Plain::User < User
  include ConnectionFields
  connection_field :login_username, :secure => true
  connection_field :login_password, :secure => true
end
