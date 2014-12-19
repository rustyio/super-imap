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
    maybe = Maybe.new
    maybe.run { fetch_internal_date_and_size }
    maybe.run { check_for_really_old_internal_date }
    maybe.run { check_for_pre_creation_internal_date }
    maybe.run { check_for_relapsed_internal_date }
    maybe.run { check_for_big_messages }
    maybe.run { fetch_uid_envelope_rfc822 }
    maybe.run { update_user_mark_email_processed }
    maybe.run { handle_tracer_email }
    maybe.run { check_for_duplicate_message_id }
    maybe.run { check_for_duplicate_sha1 }
    maybe.run { create_mail_log }
    maybe.run { deploy_webhook }
    maybe.run { update_daemon_stats }
    maybe.finish
  rescue => e
    user_thread.log_exception(e)
    user_thread.stop!
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

  def update_user(hash)
    user_thread.schedule do
      user.update_attributes!(hash)
    end
  end

  def fetch_internal_date_and_size
    responses = Timeout::timeout(30) do
      client.uid_fetch([uid], ["INTERNALDATE", "RFC822.SIZE"])
    end
    response = responses && responses.first

    # If there was no response, then skip this message.
    if response.nil?
      update_user(:last_uid => uid)
      return false
    end

    # Save the internal_date and message_size for later.
    self.internal_date = Time.parse(response.attr["INTERNALDATE"])
    self.message_size  = (response.attr["RFC822.SIZE"] || 0).to_i
    return true
  rescue Timeout::Error => e
    # If this email triggered a timeout, then skip it.
    update_user(:last_uid => uid)
    raise e
  end

  # Private: Check for a really old date. If it's old, then we should
  # stop counting on our UID knowledge and go back to loading UIDs by
  # date.
  def check_for_really_old_internal_date
    if internal_date < 4.days.ago
      update_user(:last_uid => nil, :last_uid_validity => nil)
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
      update_user(:last_uid => uid)
      return false
    else
      return true
    end
  end

  # Private: Don't process emails that are significantly older than
  # the last internal date that we've processed.
  def check_for_relapsed_internal_date
    if user.last_internal_date && internal_date < (user.last_internal_date - 1.hour)
      update_user(:last_uid => uid)
      return false
    else
      return true
    end
  end

  # Private: Skip emails that are too big.
  def check_for_big_messages
    if message_size > user_thread.options[:max_email_size]
      update_user(:last_uid => uid)
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
      update_user(:last_uid => uid)
      return false
    end

    # Save the internal_date and message_size for later.
    self.uid        = response.attr["UID"]
    self.raw_eml    = response.attr["RFC822"]
    self.envelope   = response.attr["ENVELOPE"]
    self.message_id = (envelope.message_id || "#{user.email} - #{uid} - #{internal_date}").slice(0, 255)

    return true
  rescue Timeout::Error => e
    # If this email triggered a timeout, then skip it.
    update_user(:last_uid => uid)
    raise e
  end

  # Private: Update the high-water mark for which emails we've
  # processed.
  def update_user_mark_email_processed
    # Ignore any suspicious looking internal dates. Sometimes
    # misconfigured email servers means that email arrives from the
    # future.
    if internal_date > Time.now
      internal_date = user.last_internal_date
    end

    # Update the user.
    update_user(:last_uid           => uid,
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
      update_user(:last_uid => uid)
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
    return !old_mail_log
  end

  # Private: Have we already processed this sha1 hash? This helps us
  # catch rare cases where an email doesn't have a message_id so we
  # make one up, so the message_id is unique, but the email is a
  # duplicate. This may be unnecessary.
  def check_for_duplicate_sha1
    # Generate the SHA1.
    sha1 = Digest::SHA1.hexdigest(raw_eml)

    old_mail_log = nil
    user_thread.schedule do
      old_mail_log = user.mail_logs.find_by_sha1(sha1)
    end
    return !old_mail_log
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
      daemon.processed_log << [Time.now, user.email, message_id]
    daemon.total_emails_processed += 1
    return true
  end
end
