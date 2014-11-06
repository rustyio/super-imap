class ImapTestServer::SocketState
  ChaosDisconnect = Class.new(StandardError)
  MailStruct = Struct.new(:uid, :date, :eml)

  attr_accessor :socket
  attr_accessor :state
  attr_accessor :uid_validity
  attr_accessor :new_email, :inbox

  def initialize(socket)
    self.socket = socket
    self.state = {}
    self.uid_validity = 1
  end

  # Public: Return the username of the authenticated user.
  def username
    state[:username]
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
    Log.info("Sending #{tag} #{s}")
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
    state[:username] = args[0]
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
    respond("*", %(1 EXISTS))
    respond("*", %(1 RECENT))
    respond("*", %(OK [UNSEEN 1] First unseen.))
    respond("*", %(OK [UIDVALIDITY #{uid_validity}] UIDs valid))
    respond("*", %(OK [UIDNEXT 2] Predicted next UID))
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

  # def imap_uid_search(tag, args)
  #   from_uid, to_uid = args[args.index("UID") + 1].split(":")
  #   from_uid = from_uid.to_i
  #   to_uid = to_uid.to_i

  #   SEARCH FLAGGED SINCE 1-Feb-1994
  #   * SEARCH 2 84 882
  #   S: A282 OK SEARCH completed
  # end

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
