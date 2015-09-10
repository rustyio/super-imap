fields = [
  :imap_provider_code,
  :users_count
]

@connections.map do |user|
  values = fields.map do |field|
    [field, user.send(field)]
  end
  array_to_hash(values)
end.to_json
