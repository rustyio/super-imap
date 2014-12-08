module Oauth1::DisconnectsHelper
  def oauth1_new_helper
    # Throw away our credentials.
    self.user.update_attributes!(
      :email               => nil,
      :oauth1_token        => nil,
      :oauth1_token_secret => nil,
      :connected_at        => nil)

    CallUserDisconnectedWebhook.new(user).delay.run

    redirect_to_success_url
  end
end
