fields = [
  :imap_provider_code,
  :users_count
]

@connections.map do |user|
  fields.map do |field|
    [field, user.send(field)]
  end.to_h
end.to_json
