class ImapTestServer::Mailboxes
  attr_accessor :mailboxes

  def initialize(options = {})
    self.mailboxes = {}
  end

  def count
    return self.mailboxes.count
  end

  def find(username)
    self.mailboxes[username] ||= Mailbox.new(username)
  end

  def each(&block)
    mailboxes.keys.dup.each do |username|
      yield mailboxes[username]
    end
  end

  private

  class Mailbox
    attr_accessor :username
    attr_accessor :last_uid, :mails
    MailStruct = Struct.new(:uid, :date, :message_id)

    def initialize(username)
      self.username = username
      self.last_uid = rand(999999)
      self.mails = []
    end

    def count
      return mails.length
    end

    def add_fake_message
      self.last_uid += 1
      message_id = "message-#{username}-#{last_uid}-#{rand(999999)}@localhost"
      self.mails << MailStruct.new(last_uid, Time.now, message_id)
    end

    def uid_search(from_uid, to_uid)
      mails.select do |mail|
        mail.uid >= from_uid && mail.uid <= to_uid
      end.map(&:uid)
    end

    def date_search(since_date)
      mails.select do |mail|
        mail.date > since_date
      end.map(&:uid)
    end

    def fetch(uid)
      email = self.username
      mail = mails.find do |mail|
        mail.uid == uid
      end

      Mail.new do
        from email
        to email
        date mail.date
        message_id mail.message_id
        subject "MySubject"
        body "MyBody"
      end
    end
  end
end
