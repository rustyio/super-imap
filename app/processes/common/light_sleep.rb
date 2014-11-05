module Common::LightSleep
  include Common::Stoppable

  def light_sleep(seconds = nil)
    now = Time.now
    while true
      break if stopping?
      break if seconds.present? && ((Time.now - now) >= seconds)
      sleep 1
    end
  end
end
