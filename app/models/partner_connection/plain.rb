class PartnerConnection::Plain < PartnerConnection
  def self.connection_fields
    []
  end

  connection_fields.each do |field|
    validates_presence_of field
  end
end
