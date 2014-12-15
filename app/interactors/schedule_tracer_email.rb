class ScheduleTracerEmail
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def run
    # Deliver the mail.
    uid = SecureRandom.hex(10)
    mail = TracerMailer.tracer_email(user, uid)
    user.connection.imap_provider.authenticate_smtp(mail, user)
    mail.deliver

    # Log the tracer.
    user.tracer_logs.create!(:uid => uid)
  end
end
