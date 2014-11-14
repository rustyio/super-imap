fields = [
  :tag,
  :email
]
fields.map do |field|
  [field, @user.send(field)]
end.to_h.to_json
