class Oauth1::ImapProvider < ImapProvider
  include ConnectionFields

  connection_field :oauth1_access_token_path, :required => true
  connection_field :oauth1_authorize_path, :required => true
  connection_field :oauth1_request_token_path, :required => true
  connection_field :oauth1_scope, :required => true
  connection_field :oauth1_site, :required => true

  def partner_connection_class
    Oauth1::PartnerConnection
  end

  def user_class
    Oauth1::User
  end
end
