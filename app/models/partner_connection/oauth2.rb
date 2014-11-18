class PartnerConnection::Oauth2 < PartnerConnection
  def self.connection_fields
    [
      :oauth2_client_id,
      :oauth2_client_secret
    ]
  end

  connection_fields.each do |field|
    validates_presence_of field
  end
end
