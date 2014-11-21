class Oauth2::ImapProvider < ImapProvider
  include ConnectionFields

  connection_field :oauth2_grant_type, :required => true
  connection_field :oauth2_scope, :required => true
  connection_field :oauth2_site, :required => true
  connection_field :oauth2_token_method, :required => true
  connection_field :oauth2_token_url, :required => true
end
