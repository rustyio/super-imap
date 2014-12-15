class Users::ConnectsController < Users::BaseCallbackController
  include Plain::ConnectsHelper
  include Oauth2::ConnectsHelper

  # The new and callback actions are contained in
  # Users::BaseCallbackController, which itself calls helpers
  # according to the authentication type.
end
