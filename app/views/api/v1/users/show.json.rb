{
  :tag            => @user.tag,
  :email          => @user.email,
  :connect_url    => new_users_connect_path(@user.signed_request_params),
  :disconnect_url => new_users_disconnect_path(@user.signed_request_params)
}
