class Users::DisconnectsController < Users::BaseCallbackController
  include Plain::DisconnectsHelper
  include Oauth1::DisconnectsHelper
  include Oauth2::DisconnectsHelper

  # The new and callback actions are contained in
  # Users::BaseCallbackController, which itself calls helpers
  # according to the authentication type.
end
