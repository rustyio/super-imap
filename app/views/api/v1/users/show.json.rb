{
  :tag            => @user.tag,
  :email          => @user.email,
  :connect_url    => new_users_connect_url(@user.signed_request_params),
  :disconnect_url => new_users_disconnect_url(@user.signed_request_params),
  :connected_at   => @user.connected_at
}.to_json
