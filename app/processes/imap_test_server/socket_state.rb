require 'date'

class ImapTestServer::SocketState
  NormalDisconnect = Class.new(StandardError)
  ChaosDisconnect = Class.new(StandardError)

  attr_accessor :socket
  attr_accessor :username
  attr_accessor :uid_validity
  attr_accessor :last_count
  attr_accessor :idling
  attr_accessor :new_email, :inbox
  attr_accessor :mailboxes, :mailbox

  def initialize(global_mailbox, socket)
    self.mailboxes = mailboxes
    self.socket = socket
    self.state = {}
    self.uid_validity = rand(999999)
    self.idling = false
    self.last_count = 0
  end

  # Public: Return true if we are idling.
  def idling?
    self.idling
  end

  # Public: Greet the new connection.
  def handle_connect()
    handle_command("TAG HELLO")
  end

  # Public: Handle the specified IMAP command, respond to the socket.
  def handle_command(s)
    Log.info("Received #{s}")
    tag, verb, args = parse_command(s)
    method = verb_to_method(verb)
    Log.info("Running #{method}")
    send(method, tag, args)
  end

  def send_exists_messages
    if self.mailbox && self.last_count < self.mailbox.count
      respond("*", "#{self.mailbox.count} EXISTS")
      self.last_count = mailbox.count
    end
  end

  private

  def parse_command(s)
    tag, s = /(.+?)\s+(.*)/.match(s).captures
    verb, s = /(UID SEARCH|UID_FETCH|\w+)\s*(.*)/.match(s).captures
    args = s.split(/\s+/)
    [tag, verb, args]
  end

  # Private: Given an IMAP verb, return a method. This is our chance
  # to inject some chaos into the system. Muhahaha.
  def verb_to_method(verb)
    verb = verb.downcase.gsub(/\s/, "_")
    choices = [
      [95, "imap_#{verb}".to_sym] #,
      # [3,  "imap_#{verb}_chaos".to_sym],
      # [1,  :imap_chaos_respond_no],
      # [1,  :imap_chaos_respond_bad],
      # [1,  :imap_chaos_gibberish_tagged],
      # [1,  :imap_chaos_gibberish_untagged],
      # [1,  :imap_chaos_soft_disconnect],
      # [1,  :imap_chaos_hard_disconnect],
    ]
    choose(choices)
  end

  # Private: Choose from a list of weighted choices.
  def choose(choices)
    r = rand()
    w = 0
    total_weight = choices.map(&:first).inject(&:+)
    choices.each do |weight, choice|
      w += (1.0 * weight / total_weight)
      return choice if r <= w
    end
  end

  # Private: Write a response to the socket.
  def respond(tag, s)
    socket.write("#{tag} #{s}\r\n")
    socket.flush
  end

  # CONNECT

  def imap_hello(tag, args)
    respond("*", "OK ImapTestServer ready.")
  end

  def imap_hello_chaos(tag, args)
    respond("*", "ERROR Not ready.")
  end

  # LOGIN Command
  # https://tools.ietf.org/html/rfc3501#section-6.2.3

  def imap_login(tag, args)
    self.username = args[0]
    self.mailbox = mailboxes.find(username)
    respond(tag, "OK Logged in.")
  end

  def imap_login_chaos(tag, args)
    respond(tag, "NO")
  end

  # LIST Command
  # https://tools.ietf.org/html/rfc3501#section-6.3.8

  def imap_list(tag, args)
    respond("*", %(LIST (\HasNoChildren) "." "INBOX"))
    respond("*", %(LIST (\HasNoChildren) "." "FOLDER1"))
    respond("*", %(LIST (\HasNoChildren) "." "FOLDER2"))
    respond(tag, "OK LIST Completed")
  end

  def imap_list_chaos(tag, args)
    respond("*", %(LIST (\HasNoChildren) "." "FOLDER1"))
    respond("*", %(LIST (\HasNoChildren) "." "FOLDER2"))
    respond(tag, "OK LIST Completed")
  end

  # EXAMINE Command
  # https://tools.ietf.org/html/rfc3501#section-6.3.2

  def imap_examine(tag, args)
    respond("*", %(FLAGS (\Answered \Flagged \Deleted \Seen \Draft)))
    respond("*", %(OK [PERMANENTFLAGS ()] Read-only mailbox.))
    respond("*", %(#{mailbox.count} EXISTS))
    respond("*", %(OK [UIDVALIDITY #{uid_validity}] UIDs valid))
    respond(tag, %(OK [READ-ONLY] Select completed.))
  end

  def imap_examine_chaos(tag, args)
    self.uid_validity = random(999)
    imap_examine(tag, args)
  end

  # STATUS Command
  # https://tools.ietf.org/html/rfc3501#section-6.3.10

  def imap_status(tag, args)
    mailbox_name = args[0]
    respond("*", %(STATUS #{mailbox_name} (UIDVALIDITY #{uid_validity})))
    respond(tag, %(OK STATUS completed))
  end

  def imap_status_chaos(tag, args)
    self.uid_validity = random(999)
    imap_status(tag, args)
  end

  # UID SEARCH Command
  # https://tools.ietf.org/html/rfc3501#section-6.4.4

  def imap_uid_search(tag, args)
    if args.index("UID")
      imap_uid_search_by_uid(tag, args)
    elsif args.index("SINCE")
      imap_uid_search_by_date(tag, args)
    else
      raise "Unhandled search:  #{args}"
    end
  end

  def imap_uid_search_by_uid(tag, args)
    # Parse the search request.
    from_uid, to_uid = args[args.index("UID") + 1].split(":")
    from_uid = from_uid.to_i - self.uid_validity
    to_uid = to_uid.to_i - self.uid_validity

    # Get a list of uids, offset by uid validity.
    uids = self.mailbox.uid_search(from_uid, to_uid).map do |uid|
      uid + self.uid_validity
    end

    respond("*", %(SEARCH #{uids.join(' ')}))
    respond(tag, %(OK SEARCH completed))
  end

  def imap_uid_search_by_date(tag, args)
    # Parse the search request.
    since_date = Time.parse(args[args.index("SINCE") + 1])

    # Make sure we have a valid date.
    if since_date.nil?
      raise "Unhandled date: #{args}"
    end

    # Get a list of uids, offset by uid validity.
    uids = mailbox.date_search(since_date).map do |uid|
      uid + self.uid_validity
    end

    respond("*", %(SEARCH #{uids.join(' ')}))
    respond(tag, %(OK SEARCH completed))
  end

  def imap_uid_search_chaos(tag, args)
    imap_uid_search(tag, args)
  end

  # UID FETCH Command
  # https://tools.ietf.org/html/rfc3501#section-6.4.5

  def imap_uid_fetch(tag, args)
    from_uid, to_uid = args[0].split(":")
    raise args.join(" ")
  end

  def imap_uid_fetch_chaos(tag, args)
    imap_uid_fetch(tag, args)
  end

  # IDLE Command
  # http://tools.ietf.org/html/rfc2177

  def imap_idle(tag, args)
    self.idling = true
    respond("+", "idling")
  end

  def imap_idle_chaos(tag, args)
    imap_idle(tag, args)
  end

  def imap_done(tag, args)
    respond(tag, "OK IDLE terminated")
  end

  def imap_done_chaos(tag, args)
    imap_done(tag, args)
  end

  # LOGOUT Command
  # https://tools.ietf.org/html/rfc3501#section-6.1.3

  def imap_logout(tag, args)
    respond("*", "BYE ImapTestServer logging out")
    respond(tag, "OK LOGOUT completed")
    raise NormalDisconnect.new()
  end

  def imap_logout_chaos(tag, args)
    imap_logout(tag, args)
  end

  # GENERAL CHAOS

  def imap_chaos_respond_no(tag, args)
    respond(tag, "BAD")
  end

  def imap_chaos_respond_bad(tag, args)
    respond(tag, "BAD")
  end

  def imap_chaos_gibberish_tagged(tag, args)
    respond(tag, "ZZZ")
  end

  def imap_chaos_gibberish_untagged(tag, args)
    respond("*", "ZZZ")
  end

  def imap_chaos_soft_disconnect(tag, args)
    respond("*", "BYE")
  end

  def imap_chaos_hard_disconnect(tag, args)
    raise ChaosDisconnect.new("Disconnect!")
  end
end
