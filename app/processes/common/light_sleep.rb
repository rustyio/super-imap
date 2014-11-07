module Common::LightSleep
  include Common::Stoppable

  def light_sleep(seconds = nil)
    now = Time.now
    while running?
      break if seconds.present? && ((Time.now - now) >= seconds)
      sleep 1
    end
  end
end
