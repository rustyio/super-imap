class Common::CsvLog
  include Common::Stoppable
  include Common::WrappedThread

  attr_accessor :log_path
  attr_accessor :log_filehandle
  attr_accessor :log_queue
  attr_accessor :log_thread

  def initialize(log_path)
    init_stoppable
    self.log_path   = log_path
    self.log_queue  = Queue.new
    self.log_thread = wrapped_thread do
      _thread_runner
    end
  end

  def log(*values)
    self.log_queue << values
  end

  private

  def _thread_runner
    self.log_filehandle = File.open(log_path, "w")
    while running?
      _drain_queue
      sleep 0.1
    end
    _drain_queue
    _close_file
  end

  def _drain_queue
    while true
      # Don't block, otherwise we can't exit.
      values = log_queue.pop(true)
      log_filehandle.write(values.join(",") + "\n")
    end
  rescue ThreadError => e
    # Thrown when queue is empty.
    log_filehandle.flush()
  end

  def _close_file
    log_filehandle.close
  rescue IOError
    # May fire if we've already closed the stream elsewhere.
  end
end
