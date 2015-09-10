fields = [
  :imap_provider_code,
  :users_count
]
values = fields.map do |field|
  [field, @connection.send(field)]
end
array_to_hash(values).to_json
