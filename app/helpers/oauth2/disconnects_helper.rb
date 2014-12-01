module Oauth2::DisconnectsHelper
  def oauth2_new_helper
    # Disconnect the user. Assume that this succeeds.
    token = self.user.oauth2_refresh_token
    url = "https://accounts.google.com/o/oauth2/revoke?token=#{token}"
    Net::HTTP.get_response(URI(url))

    # Throw away our credentials.
    self.user.update_attributes!(
      :email => nil,
      :oauth2_refresh_token => nil )

    # Redirect.
    redirect_to partner.success_url
  end
end
