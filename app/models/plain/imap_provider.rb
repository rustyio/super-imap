class Plain::ImapProvider < ImapProvider
  include ConnectionFields

  connection_field :host
  connection_field :port
  connection_field :use_ssl
end
