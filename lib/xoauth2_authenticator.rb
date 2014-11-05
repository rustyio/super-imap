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
