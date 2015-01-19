class Oauth2::PartnerConnection < PartnerConnection
  include ConnectionFields
  connection_field :oauth2_client_id, :required => true
  connection_field :oauth2_client_secret, :required => true, :secure => true
end
