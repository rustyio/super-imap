#  IMAP::UserThread - Manages the interactions of a single user
#  against an IMAP server. Written in a "crash-only" style. If
#  something goes wrong, we tear down the whole thread and start from
#  scratch.
#
#  The basic lifecycle is:
#
#  + Connects to the server.
#  + Catch up on email we may have missed.
#  + Go into IMAP IDLE mode.
#  + Pop out of IDLE mode, catch up on emails.
#  + Repeat until we get a "terminate" signal.
#  + When terminated, or on error, disconnect ourselves.

require 'net/imap'

class IMAP::UserThread
  attr_accessor :daemon, :options
  attr_accessor :user, :client, :folder_name, :stop

  def initialize(daemon, user_id, options)
    self.daemon = daemon
    self.user = User.find(user_id).include(:partner_connection => :connection_type)
    self.options = options
    self.stop = false
  end

  def run
    connect
    authenticate
    choose_folder
    read_email
    if valid_uid?
      read_email_by_uid
    else
      read_email_by_date
    end
    listen_for_emails
  ensure
    daemon.schedule_work("disconnect_user", :user_id => user.id)
    disconnect
  end

  private unless Rails.env.test?

  # Private: Connect to the server, set the client.
  def connect
    conn_type = user.connection.connection_type
    log.info("IMAP::UserThread - #{user.id} - Connecting to #{conn_type.host}")
    self.client = Net::IMAP.new(conn_type.host, :port => conn_type.port, :ssl => conn_type.use_ssl)
  end

  # Private: Authenticate a user to the server.
  def authenticate
    log.info("IMAP::UserThread - #{user.id} - Authenticating")
    Authenticator.new(user).authenticate(client)
    user.update_attributes(:last_connected_at => Time.now)
  end

  # Private: Fetch a list of folders, choose the first one that looks
  # promising.
  def choose_folder
    log.info("IMAP::UserThread - #{user.id} - Choosing folder.")

    best_folders = [
      "[Gmail]/All Mail",
      "[Google Mail]/All Mail",
      "INBOX"
    ]

    # Discover the folder.
    client.list("", "*").each do |folder|
      if best_folders.include?(folder.name)
        log.info("IMAP::UserThread - Examining #{folder.name}")
        self.folder_name = folder.name
        break
      end
    end

    # Examine the folder.
    client.examine(folder_name)
  end

  # Private: Start a loop that alternates between idling and reading
  # email.
  def listen_for_emails
    while true
      idle
      read_email_by_uid
    end
  end

  # Private: Return true if our knowledge of the server's uid is still
  # valid. See "http://tools.ietf.org/html/rfc4549#section-4.1"
  def valid_uid?
    # Get the latest validity value.
    response = client.status(folder_name.to_s, attrs=['UIDVALIDITY'])
    uid_validity = response['UIDVALIDITY']

    # Check if our knowledge of the server's uid is still valid.
    is_valid = uid_validity &&
               user.last_uid &&
               user.last_uid_validity &&
               (uid_validity.to_s == user.last_uid_validity.to_s)

    # Update the user with the new validity value.
    user.update_attributes(:last_uid_validity => uid_validity)

    return is_valid
  end

  # Private: Search for new email by uid. See
  # "https://tools.ietf.org/html/rfc3501#section-2.3.1.1"
  def read_email_by_uid
    # HACK - Library doesn't work with "UID N:*". Just use a really
    # big ending number.
    max_uid = 2 ** 32 - 1
    client.uid_search(["UID", "#{user.last_uid + 1}:#{max_uid}"]).each do |uid|
      break if stop

      schedule do
        self.process_uid(uid)
      end
    end
  end

  # Private: Search for new email by date. See
  # "https://tools.ietf.org/html/rfc3501#section-6.4.4"
  def read_email_by_date
    # Search by date. Unfortunately, IMAP date searching isn't very
    # granular. To ensure we get all emails we go back two full
    # days. We filter out duplicates later.
    date_string = 2.days.ago.strftime("%d-%b-%Y")
    client.uid_search(["SINCE", date_string]).each do |uid|
      break if stop

      schedule do
        self.process_uid(uid)
      end
    end
  end

  # Private: Put the connection into idle mode, exit when we receive a
  # new EXISTS message.
  # See "https://tools.ietf.org/html/rfc3501#section-7.3.1"
  def wait_for_email
    client.idle do |response|
      if response &&
         response.respond_to?(:name) &&
         response.name == "EXISTS"
        client.idle_done()
      end
    end
  end

  # Private: Schedule a block of code to run in a worker thread
  # (rather than a user thread).
  #
  # We do this in order to prevent ourselves from exhausting memory
  # and redlining the CPU at startup or at times of lots of email
  # activity. This helps smooth out the load.
  #
  # Without this, we would have all the user threads (500 by default)
  # trying to crunch through emails as quickly as possible at the same
  # time.
  def schedule(&block)
    # If testing, just run the logic.
    if Rails.env.test
      block.call()
      return
    end

    # Schedule the block to run on a worker thread, and put ourselves to sleep.
    daemon.schedule_work("block", :user_id => user.id,
                         :block => block, :thread => Thread.current)

    # Put ourselves to sleep.
    Thread.sleep
  end

  # Private: Read and act on a single email. Keep in mind that this is
  # *not* run in a user thread, but rather in a worker thread.
  #
  # + uid - The UID of the email.
  def process_uid(uid)
    responses = client.uid_fetch([@uid], ["INTERNALDATE", "RFC822.SIZE", "UID"])
    response = responses.first

    # Check for a really old date. If it's old, then we should stop
    # counting on our UID knowledge and go back to loading UIDs by
    # date.
    internal_date = Time.parse(response.attr["INTERNALDATE"])
    if internal_date < 4.days.ago
      user.update_attributes(:last_uid => nil, :last_uid_validity => nil)
      self.stop = true
      return
    end

    # Don't process emails that arrived before this user was created.
    if internal_date < user.created_at
      return
    end

    # Don't process emails that are significantly older than the last internal date that we've processed.
    if internal_date < (user.last_internal_date - 1.hour)
      return
    end

    # Skip emails that are too big.
    message_size = (response.attr["RFC822.SIZE"] || 0).to_i
    if message_size > self.options[:max_email_size]
      return
    end

    # Ignore any suspicious looking internal dates. Sometimes
    # misconfigured email servers means that email arrives from the
    # future.
    if internal_date > Time.now
      internal_date = user.last_internal_date
    end

    # Load the email body.
    responses = self.client.uid_fetch([uid], ["ENVELOPE", "RFC822", "UID"])
    response = responses.first
    uid = response.attr["UID"]
    raw_eml = response.attr["RFC822"]

    # Update the user.
    user.update_attributes(:last_uid           => uid,
                           :last_email_at      => Time.now,
                           :last_internal_date => internal_date)

    # Get the message_id.
    envelope = response.attr["ENVELOPE"]
    message_id = envelope.message_id || "#{user.email} - #{uid} - #{internal_date}"
    message_id = message_id.slice(0, 255)

    # Generate the md5.
    md5 = Digest::MD5.hexdigest(raw_eml.slice(0, 10000))

    # Have we already processed this one?
    if user.mail_logs.find(:md5 => md5)
      return
    end

    # Create the mail log record.
    mail_log = user.mail_logs.create(:message_id => envelope.message_id, :md5 => md5)

    # Transmit to the partner's webhook.
    System::TransmitToWebhook.new(mail_log, raw_eml).delay.run
  end

  # Private: Logout the user, disconnect the client.
  def disconnect
    client && client.logout
    client && client.disconnect
    self.client = nil
  end
end
