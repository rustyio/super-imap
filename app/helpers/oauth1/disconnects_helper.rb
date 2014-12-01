module Oauth1::DisconnectsHelper
  def oauth1_new_helper
    redirect_to partner.success_url
  end
end
