class Oauth1::PartnerConnection < PartnerConnection
  include ConnectionFields
  connection_field :oauth1_consumer_key, :required => true, :secure => true
  connection_field :oauth1_consumer_secret, :required => true, :secure => true
end
