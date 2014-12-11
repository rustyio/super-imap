class Oauth1::User < User
  include ConnectionFields
  before_save :update_connected_at

  connection_field :email
  connection_field :oauth1_token, :secure => true
  connection_field :oauth1_token_secret, :secure => true

  def update_connected_at
    if email.present? && oauth1_token.present? && oauth1_token_secret.present?
      self.connected_at ||= Time.now
    else
      self.connected_at = nil
    end
  end
end
