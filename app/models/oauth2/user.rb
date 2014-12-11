class Oauth2::User < User
  include ConnectionFields
  before_save :update_connected_at

  connection_field :email
  connection_field :oauth2_refresh_token, :secure => true

  def update_connected_at
    if email.present? && oauth2_refresh_token.present?
      self.connected_at ||= Time.now
    else
      self.connected_at = nil
    end
  end
end
