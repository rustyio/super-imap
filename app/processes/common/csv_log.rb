module Common::CsvLog
  include Common::Stoppable
  include Common::WrappedThread

  def start_csv_log_thread
    _csv_log_initialize
    wrapped_thread do
      _csv_log_thread_runner
    end
  end

  def csv_log(path)
    _csv_log_initialize
    @csv_log_filehandles[path] ||= File.open(path, "w")
    @csv_log_queues[path] ||= Queue.new
    @csv_log_paths << path
    @csv_log_queues[path]
  end

  def close_csv_logs
    _csv_log_initialize
    @csv_log_paths.each do |path|
      begin
        @csv_log_filehandles[path].close
      rescue IOError
        # May fire if we've already closed the stream elsewhere.
      end
    end
  end

  private

  def _csv_log_initialize
    @csv_log_paths ||= []
    @csv_log_filehandles ||= {}
    @csv_log_queues ||= {}
  end

  def _csv_log_thread_runner
    while running?
      @csv_log_paths.each do |path|
        queue = @csv_log_queues[path]
        file = @csv_log_filehandles[path]
        _csv_log_drain_queue(queue, file)
      end
      sleep 0.1
    end
    close_csv_logs
  end

  def _csv_log_drain_queue(queue, file)
    while running?
      # Don't block, otherwise we can't exit.
      values = queue.pop(true)
      file.write(values.join(",") + "\n")
      file.flush()
    end
  rescue ThreadError => e
    # Queue is empty, return.
    file.flush()
  end
end
