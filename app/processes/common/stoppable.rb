module Common::Stoppable
  def init_stoppable
    @stop = false
    @stop_lock = Mutex.new
  end

  def trap_signals
    Signal.trap("INT") do self.stop! end
    Signal.trap("TERM") do self.stop! end
  end

  def stop!
    @stop_lock.synchronize do
      @stop = true
    end
  end

  def running?
    @stop_lock.synchronize do
      @stop != true
    end
  end

  def stopping?
    @stop_lock.synchronize do
      @stop == true
    end
  end
end
