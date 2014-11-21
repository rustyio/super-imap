{
  :tag            => @user.tag,
  :email          => @user.email,
  :connect_url    => new_user_connect_path(@user.signed_request_params)
  :disconnect_url => new_user_disconnect_path(@user.signed_request_params)
}
