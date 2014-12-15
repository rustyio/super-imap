class TracerMailer < ActionMailer::Base
  def tracer_email(user, uid)
    @uid = uid
    mail(:from => user.email,
         :to => user.email,
         :subject => "TRACER: #{uid}")
  end
end
