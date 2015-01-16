class ScheduleTracerEmails
  attr_accessor :user, :num_tracers

  def initialize(user, num_tracers)
    self.user = user
    self.num_tracers = num_tracers
  end

  def run
    num_tracers.times.each do |n|
      send_tracer_to_user(user)
    end
  end

  def send_tracer_to_user(user)
    # Deliver the mail.
    uid = SecureRandom.hex(10)
    mail = TracerMailer.tracer_email(user, uid)
    user.connection.imap_provider.authenticate_smtp(mail, user)
    mail.deliver
    Log.librato(:measure, 'app.schedule_tracer_email.count', 1)

    # Log the tracer.
    user.tracer_logs.create!(:uid => uid)
  end
end
