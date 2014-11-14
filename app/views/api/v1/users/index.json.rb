fields = [:tag, :email]

@users.map do |user|
  fields.map do |field|
    [field, user.send(field)]
  end.to_h
end.to_json
