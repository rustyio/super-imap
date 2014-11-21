#  ImapClient::UserThread - Manages the interactions of a single user
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

class ImapClient::UserThread
  include Common::LightSleep
  include Common::Stoppable

  attr_accessor :daemon, :options
  attr_accessor :user, :client, :folder_name

  def initialize(daemon, user, options)
    self.daemon = daemon
    self.user = user
    self.options = options
  end

  def run
    delay_start
    connect
    authenticate
    choose_folder
    update_uid_validity
    main_loop
  rescue => e
    Log.exception(e)
    self.daemon.increment_error_count(user.id)
    stop!
  ensure
    stop!
    daemon.schedule_work(:disconnect_user, :hash => user.id, :user_id => user.id)
    disconnect
  end

  private unless Rails.env.test?

  # Private: Exponentially backoff based on the number of errors we
  # are seeing for a given user. At most, wait 5 minutes before trying to connect.
  def delay_start
    errors  = self.daemon.error_count(user.id)
    seconds = (errors ** 3) - 1
    seconds = [seconds, 300].min
    light_sleep seconds
  end

  # Private: Connect to the server, set the client.
  def connect
    conn_type = user.imap_provider
    self.client = Net::IMAP.new(conn_type.host, :port => conn_type.port, :ssl => conn_type.use_ssl)
  end

  # Private: Authenticate a user to the server.
  def authenticate
    ImapClient::Authenticator.new(user).authenticate(client)
    schedule do
      user.update_attributes(:last_login_at => Time.now)
    end
  end

  # Private: Fetch a list of folders, choose the first one that looks
  # promising.
  def choose_folder
    # TODO: This should probably live in the imap_provider model.
    best_folders = [
      "[Gmail]/All Mail",
      "[Google Mail]/All Mail",
      "INBOX"
    ]

    # Discover the folder.
    client.list("", "*").each do |folder|
      if best_folders.include?(folder.name)
        self.folder_name = folder.name
        break
      end
    end

    # Examine the folder.
    client.examine(folder_name)
  end

  # Private: Return true if our knowledge of the server's uid is still
  # valid. See "http://tools.ietf.org/html/rfc4549#section-4.1"
  def update_uid_validity
    # Get the latest validity value.
    response = client.status(folder_name.to_s, attrs=['UIDVALIDITY'])
    uid_validity = response['UIDVALIDITY']

    if user.last_uid_validity.to_s != uid_validity.to_s
      schedule do
        # Update the user with the new validity value, invalidate the
        # old last_uid value.
        user.update_attributes(:last_uid_validity => uid_validity, :last_uid => nil)
      end
    end
  end

  # Private: Start a loop that alternates between idling and reading
  # email.
  def main_loop
    while running?
      # Read emails until we have read everything there is to
      # read. Then go into idle mode.
      last_read_count = 9999
      while running? && last_read_count > 0
        if user.last_uid.present?
          last_read_count = read_email_by_uid
        else
          last_read_count = read_email_by_date
        end
      end

      # Maybe we stopped?
      break if stopping?

      wait_for_email
    end
  end

  # Private: Search for new email by uid. See
  # "https://tools.ietf.org/html/rfc3501#section-2.3.1.1"e
  #
  # Returns the number of emails read.
  def read_email_by_uid
    # HACK - Library doesn't work with "UID N:*". Just use a really
    # big ending number.
    max_uid = 2 ** 32 - 1
    uids = client.uid_search(["UID", "#{user.last_uid + 1}:#{max_uid}"])
    uids.each do |uid|
      break if stopping?
      schedule do
        process_uid(uid) unless stopping?
      end
    end

    return uids.count
  end

  # Private: Search for new email by date. See
  # "https://tools.ietf.org/html/rfc3501#section-6.4.4"
  #
  # Returns the number of uids read.
  def read_email_by_date
    # Search by date. Unfortunately, IMAP date searching isn't very
    # granular. To ensure we get all emails we go back two full
    # days. We filter out duplicates later.
    date_string = 2.days.ago.strftime("%d-%b-%Y")
    uids = client.uid_search(["SINCE", date_string])
    uids.each do |uid|
      break if stopping?
      schedule do
        process_uid(uid) unless stopping?
      end
    end

    return uids.count
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
      elsif stopping?
        client.idle_done()
      end
    end
  end

  # Private: Schedule a block of code to run in a worker thread
  # (rather than a user thread).
  #
  # We do this in order to prevent ourselves from using too many
  # database connections, exhausting memory, and redlining the CPU at
  # startup or at times of lots of email activity. This helps smooth
  # out the load.
  #
  # Without this, we would have all the user threads (500 by default)
  # maintaining separate database connections and trying to crunch
  # through emails as quickly as possible at the same time.
  def schedule(&block)
    # Schedule the block to run on a worker thread, and put ourselves to sleep.
    daemon.schedule_work(:callback,
                         :hash    => user.id,
                         :user_id => user.id,
                         :block   => block,
                         :thread  => Thread.current)

    # Put ourselves to sleep. The worker will call Thread.run to wake us back up.
    sleep
  end

  # Private: Read and act on a single email. Keep in mind that this is
  # *not* run in a user thread, but rather in a worker thread.
  #
  # + uid - The UID of the email.
  def process_uid(uid)
    responses = client.uid_fetch([uid], ["INTERNALDATE", "RFC822.SIZE"])
    response = responses.first

    # Check for a really old date. If it's old, then we should stop
    # counting on our UID knowledge and go back to loading UIDs by
    # date.
    internal_date = Time.parse(response.attr["INTERNALDATE"])
    if internal_date < 4.days.ago
      user.update_attributes(:last_uid => nil, :last_uid_validity => nil)
      stop!
      return
    end

    # Don't process emails that arrived before this user was created.
    if internal_date < user.created_at
      return
    end

    # Don't process emails that are significantly older than the last internal date that we've processed.
    if user.last_internal_date && internal_date < (user.last_internal_date - 1.hour)
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
    responses = self.client.uid_fetch([uid], ["UID", "ENVELOPE", "RFC822"])
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

    # Have we already processed this one?
    if user.mail_logs.find_by_message_id(message_id)
      return
    end

    # Generate the SHA1.
    sha1 = Digest::SHA1.hexdigest(raw_eml.slice(0, 10000))

    # Have we already processed this one?
    if user.mail_logs.find_by_sha1(sha1)
      return
    end

    # Create the mail log record.
    mail_log = user.mail_logs.create(:message_id => message_id, :sha1 => sha1)

    # Transmit to the partner's webhook.
    unless self.daemon.stress_test_mode
      TransmitToWebhook.new(mail_log, envelope, raw_eml).delay.run
    end

    # Update stats.
    self.daemon.clear_error_count(user.id)
    self.daemon.processed_log &&
      self.daemon.processed_log << [Time.now, user.email, message_id]
    self.daemon.total_emails_processed += 1
  rescue => e
    Log.exception(e)
    self.daemon.increment_error_count(user.id)
    stop!
  end

  # Private: Logout the user, disconnect the client.
  def disconnect
    client && client.logout
    client && client.disconnect
    self.client = nil
  rescue => e
    Log.exception(e)
  end
end
