class Oauth1::PartnerConnection < PartnerConnection
  def self.connection_fields
    [
      :oauth1_consumer_key,
      :oauth1_consumer_secret
    ]
  end

  connection_fields.each do |field|
    validates_presence_of field
  end
end
