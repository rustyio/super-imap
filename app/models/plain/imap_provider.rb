class Plain::ImapProvider < ImapProvider
  include ConnectionFields

  connection_field :host
  connection_field :port
  connection_field :use_ssl

  def partner_connection_class
    Plain::PartnerConnection
  end

  def user_class
    Plain::User
  end
end
