require 'net/imap'

class Net::IMAP
  class XOAuth2Authenticator
    def initialize(email_address, access_token)
      @email_address = email_address
      @access_token = access_token
    end

    def process(s)
      "user=#{@email_address}\x01auth=Bearer #{@access_token}\x01\x01"
    end
  end

  add_authenticator 'XOAUTH2', XOAuth2Authenticator
end

class Net::SMTP
  def auth_xoauth2(email_address, access_token)
    res = critical {
      auth_string = "user=#{email_address}\x01auth=Bearer #{access_token}\x01\x01"
      get_response('AUTH XOAUTH2 ' + base64_encode(auth_string))
    }
    check_auth_response res
    res
  end
end
