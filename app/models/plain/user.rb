class Plain::User < User
  include ConnectionFields
  connection_field :login_username
  connection_field :login_password
end
