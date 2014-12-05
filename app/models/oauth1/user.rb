class Oauth1::User < User
  include ConnectionFields
  connection_field :email
  connection_field :oauth1_token, :secure => true
  connection_field :oauth1_token_secret, :secure => true
end
