class Plain::User < User
  include ConnectionFields
  before_save :update_connected_at

  connection_field :login_username
  connection_field :login_password, :secure => true

  def update_connected_at
    if login_username.present? && login_password.present?
      self.connected_at ||= Time.now
    else
      self.connected_at = nil
    end
  end
end
