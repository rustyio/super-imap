module Common::Stoppable
  attr_accessor :stop

  def trap_signals
    Signal.trap("INT") do self.stop = true end
    Signal.trap("TERM") do self.stop = true end
  end

  def stop!
    self.stop = true
  end

  def running?
    self.stop != true
  end

  def stopping?
    self.stop == true
  end
end
