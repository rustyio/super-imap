module AuthMethodHelper
  def auth_method_plain?
    /^plain$/i.match(self.auth_method)
  end

  def auth_method_oauth1?
    /^oauth1$/i.match(self.auth_method)
  end

  def auth_method_oauth2?
    /^oauth2$/i.match(self.oauth_method)
  end
end
