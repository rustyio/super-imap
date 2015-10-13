# Private: Read and act on a single email. This is one place where
# Ruby support for monads would be useful. The challenge is that we
# have to verify a lot of data in a very specific sequence, and at any
# time we could either abort (ie: skip the remaining operations) or
# raise an exception.
#
# We build something similar by creating a 'Maybe' control structure
# where we submit blocks of code to an object. A block is considered
# successful if it returns true and doesn't throw any exceptions. If a
# block is not successful, we skip the remaining blocks.
#
# Note that every database touch is wrapped in a call to
# `user_thread.schedule(&block)`. This allows us to avoid creating a
# separate database connection for each user thread.
class ProcessUid
  attr_accessor :user_thread, :uid
  attr_accessor :internal_date, :message_size
  attr_accessor :raw_eml, :envelope
  attr_accessor :message_id, :sha1
  attr_accessor :mail_log

  def initialize(user_thread, uid)
    self.user_thread = user_thread
    self.uid = uid
  end

  # Public: Process the email.
  def run
    # Run all the steps below. Stop as soon as one of them returns
    # false or throws an error.
    true &&
      fetch_internal_date_and_size  &&
      check_for_really_old_internal_date  &&
      check_for_pre_creation_internal_date  &&
      check_for_relapsed_internal_date  &&
      check_for_big_messages  &&
      fetch_uid_envelope_rfc822  &&
      update_user_mark_email_processed  &&
      handle_tracer_email  &&
      check_for_duplicate_message_id  &&
      check_for_duplicate_sha1  &&
      create_mail_log  &&
      deploy_webhook  &&
      update_daemon_stats
  ensure
    clean_up
  end

  # Private: The User model.
  def user
    user_thread.user
  end

  # Private: The IMAP client instance.
  def client
    user_thread.client
  end

  # Private: The imap_client daemon.
  def daemon
    user_thread.daemon
  end

  private

  def confirm_tracer(tracer_uid)
    user_thread.schedule do
      tracer = TracerLog.find_by_uid(tracer_uid) || TracerLog.new(:uid => tracer_uid)
      tracer.update_attributes!(:detected_at => Time.now)
    end
  end

  def fetch_internal_date_and_size
    responses = Timeout::timeout(30) do
      client.uid_fetch([uid], ["INTERNALDATE", "RFC822.SIZE"])
    end
    response = responses && responses.first

    # If there was no response, then skip this message.
    if response.nil?
      user_thread.update_user(:last_uid => uid)
      return false
    end

    # Save the internal_date and message_size for later.
    self.internal_date = Time.parse(response.attr["INTERNALDATE"])
    self.message_size  = (response.attr["RFC822.SIZE"] || 0).to_i

    return true
  rescue Timeout::Error => e
    # If this email triggered a timeout, then skip it.
    user_thread.update_user(:last_uid => uid)
    raise e
  end

  # Private: Check for a really old date. If it's old, then we should
  # stop counting on our UID knowledge and go back to loading UIDs by
  # date.
  def check_for_really_old_internal_date
    if internal_date < 4.days.ago
      Log.librato(:count, "system.process_uid.really_old_internal_date", 1)
      user_thread.update_user(:last_uid => nil, :last_uid_validity => nil)
      user_thread.stop!
      return false
    else
      return true
    end
  end

  # Private: Don't process emails that arrived before this user was
  # created.
  def check_for_pre_creation_internal_date
    if internal_date < user.created_at
      Log.librato(:count, "system.process_uid.pre_creation_internal_date", 1)
      user_thread.update_user(:last_uid => uid)
      return false
    else
      return true
    end
  end

  # Private: Don't process emails that are significantly older than
  # the last internal date that we've processed.
  def check_for_relapsed_internal_date
    if user.last_internal_date && internal_date < (user.last_internal_date - 1.hour)
      Log.librato(:count, "system.process_uid.relapsed_internal_date", 1)
      user_thread.update_user(:last_uid => uid)
      return false
    else
      return true
    end
  end

  # Private: Skip emails that are too big.
  def check_for_big_messages
    if message_size > user_thread.options[:max_email_size]
      Log.librato(:count, "system.process_uid.big_message", 1)
      user_thread.update_user(:last_uid => uid)
      return false
    else
      return true
    end
  end

  def fetch_uid_envelope_rfc822
    # Load the email body.
    responses = Timeout::timeout(30) do
      self.client.uid_fetch([uid], ["UID", "ENVELOPE", "RFC822"])
    end
    response = responses && responses.first

    # If there was no response, then skip this message.
    if response.nil?
      Log.librato(:count, "system.process_uid.uid_fetch_no_response", 1)
      user_thread.update_user(:last_uid => uid)
      return false
    end

    # Save the internal_date and message_size for later.
    self.uid        = response.attr["UID"]
    self.raw_eml    = to_utf8(response.attr["RFC822"])
    self.envelope   = response.attr["ENVELOPE"]
    self.message_id = (envelope.message_id || "#{user.email} - #{uid} - #{internal_date}").slice(0, 255)

    return true
  rescue Timeout::Error => e
    # If this email triggered a timeout, then skip it.
    user_thread.update_user(:last_uid => uid)
    raise e
  end

  # Private: Update the high-water mark for which emails we've
  # processed.
  def update_user_mark_email_processed
    # Ignore any suspicious looking internal dates. Sometimes
    # misconfigured email servers means that email arrives from the
    # future.
    if internal_date > Time.now
      Log.librato(:count, "system.process_uid.fix_suspicious_internal_date", 1)
      self.internal_date = user.last_internal_date
    end

    # Update the user.
    user_thread.update_user(:last_uid           => uid,
                            :last_email_at      => Time.now,
                            :last_internal_date => internal_date)
    return true
  end

  # Private: Is this a tracer? If so, update the TracerLog and stop
  # processing.
  def handle_tracer_email
    if m = /^TRACER: (.+)$/.match(envelope.subject)
      tracer_uid = m[1]
      confirm_tracer(tracer_uid)
      user_thread.update_user(:last_uid => uid)
      daemon.total_emails_processed += 1
      return false
    else
      return true
    end
  end

  # Private: Have we already processed this message_id?
  def check_for_duplicate_message_id
    old_mail_log = nil
    user_thread.schedule do
      old_mail_log = user.mail_logs.find_by_message_id(message_id)
    end

    if old_mail_log
      Log.librato(:count, "system.process_uid.duplicate_message_id", 1)
      return false
    else
      return true
    end
  end

  # Private: Have we already processed this sha1 hash? This helps us
  # catch rare cases where an email doesn't have a message_id so we
  # make one up, so the message_id is unique, but the email is a
  # duplicate. This may be unnecessary.
  def check_for_duplicate_sha1
    # Generate the SHA1.
    self.sha1 = Digest::SHA1.hexdigest(raw_eml)

    old_mail_log = nil
    user_thread.schedule do
      old_mail_log = user.mail_logs.find_by_sha1(sha1)
    end

    if old_mail_log
      Log.librato(:count, "system.process_uid.duplicate_sha1", 1)
      return false
    else
      return true
    end
  end

  # Private: Log the mail.
  def create_mail_log
    user_thread.schedule do
      self.mail_log = user.mail_logs.create(:message_id => message_id, :sha1 => sha1)
    end
    return true
  end

  # Private: Deploy the web hook.
  def deploy_webhook
    unless daemon.stress_test_mode
      user_thread.schedule do
        CallNewMailWebhook.new(mail_log, envelope, raw_eml).delay.run
      end
    end
    return true
  end

  # Private: Update stats
  def update_daemon_stats
    daemon.clear_error_count(user.id)
    daemon.processed_log &&
      daemon.processed_log.log(Time.now, user.email, message_id)
    daemon.total_emails_processed += 1
    return true
  end

  # Private: Help the garbage collector know what it can collect.
  def clean_up
    self.user_thread = nil
    self.uid = nil
    self.internal_date = nil
    self.raw_eml = nil
    self.envelope = nil
    self.message_id = nil
    self.sha1 = nil
    self.mail_log = nil
  end

  # Private: Convert a string UTF-8 format.
  def to_utf8(s)
    return nil if s.nil?

    # Attempt to politely transcode the string.
    s.encode("UTF-8").scrub
  rescue
    # If that doesn't work, then overwrite the existing encoding and
    # clobber any strange characters.
    s.force_encoding("UTF-8").scrub
  end
end
