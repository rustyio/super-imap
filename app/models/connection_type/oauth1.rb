class ConnectionType::Oauth1 < ConnectionType
  def self.connection_fields
    [
      :oauth1_access_token_path, :oauth1_authorize_path,
      :oauth1_request_token_path, :oauth1_scope, :oauth1_site
    ]
  end

  connection_fields.each do |field|
    validates_presence_of field
  end
end
