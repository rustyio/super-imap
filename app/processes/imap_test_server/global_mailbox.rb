class ImapTestServer::GlobalMailbox
  attr_accessor :first_uid, :last_uid, :start_date, :end_date, :date_incr

  def initialize(options = {})
    self.first_uid  = rand(9999999)
    self.last_uid   = first_uid + (options[:num_emails] || 500)
    self.start_date = options[:start_date] || 1.day.ago
    self.end_date   = options[:end_date]   || 5.days.from_now
    self.date_incr  = (end_date - start_date) / (last_uid - first_uid)
  end

  def uid_search(from_uid, to_uid)
    from_uid = [first_uid, from_uid].max
    to_uid   = [last_uid, to_uid].min
    Log.info("Responding in uid_search: #{from_uid}:#{to_uid}")
    return (from_uid..to_uid).to_a
  end

  def date_search(since_date)
    since_date = [since_date, start_date].max
    offset_uid = ((since_date - start_date) / date_incr).to_i
    from_uid = first_uid + offset_uid
    Log.info("Responding in date_search: #{from_uid}:#{last_uid}")
    (from_uid..last_uid).to_a
  end

  def fetch(username, uid)
  end

  private

  def user_mailbox(username)

  end
end
