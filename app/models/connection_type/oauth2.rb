class ConnectionType::Oauth2 < ConnectionType
  def connection_fields
    [
      :oauth2_grant_type, :oauth2_scope, :oauth2_site,
      :oauth2_token_method, :oauth2_token_url
    ]
  end

  connection_fields.each do |field|
    validates_presence_of field
  end
end
