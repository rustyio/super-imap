class Oauth1::User < User
  include ConnectionFields
  connection_field :email
  connection_field :oauth1_token
  connection_field :oauth1_token_secret
end
