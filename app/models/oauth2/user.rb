class Oauth2::User < User
  include ConnectionFields
  connection_field :email
  connection_field :oauth2_refresh_token
end
