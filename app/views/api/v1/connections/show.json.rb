fields = [
  :code,
  :users_count
]
fields.map do |field|
  [field, @connection.send(field)]
end.to_h.to_json
