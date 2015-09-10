module Common::WorkerPool
  include Common::Stoppable
  include Common::WrappedThread
  include Common::DbConnection

  attr_accessor :work_queues, :worker_rhash, :worker_threads, :work_queue_latency

  # Public: Start a number of worker threads and begin processing
  # scheduled work.
  def start_worker_pool(num_worker_threads)
    # Worker stuff.
    self.work_queues = []
    self.worker_threads = []
    self.worker_rhash = ImapClient::RendezvousHash.new([])

    # Create work queues.
    num_worker_threads.times do |n|
      self.work_queues << Queue.new
    end

    # Start worker threads.
    num_worker_threads.times do |n|
      _start_worker_thread(self.work_queues[n])
    end

    tags = num_worker_threads.times.map(&:to_i)
    self.worker_rhash = ImapClient::RendezvousHash.new(tags)
  end

  # Public: Schedule a task to be executed on one of the work
  # queues. If a :hash option is provided, then use this to
  # consistently send the work to the same worker. This allows us to
  # effectively "single thread" some lines of work.
  #
  # s - The command to schedule.
  # options - Options for the command.
  #
  # Returns nothing.
  def schedule_work(s, options)
    raise "No hash specified!" if options[:hash].nil?
    index = worker_rhash.hash(options[:hash] || rand())
    options.merge!(:'$action' => s, :'$time' => Time.now)
    work_queues[index] << options
  end

  # Public: Return the total number of scheduled items in the work queue.
  def work_queue_length
    work_queues.map(&:size).inject(&:+)
  end

  # Public: Wait for the worker pool to finish processing all items.
  def terminate_worker_pool
    Log.info("Waiting for worker threads...")
    worker_threads.present? && worker_threads.map(&:terminate)
  end

  private

  def _start_worker_thread(work_queue)
    self.worker_threads << wrapped_thread do
      establish_db_connection
      _worker_thread_runner(work_queue)
    end
  end

  def _worker_thread_runner(work_queue)
    # Create a work queue.
    while running?
      _worker_thread_next_action(work_queue)
    end
  end

  def _worker_thread_next_action(queue)
    # Don't block, otherwise we can't exit.
    options = queue.pop(true)
    method = "action_#{options[:'$action']}".to_sym

    # Run the action.
    begin
      self.send(method.to_sym, options)
    rescue => e
      Log.exception(e)
    end

    # Track the most recent latency.
    self.work_queue_latency = Time.now - options[:'$time']
  rescue ThreadError => e
    # Queue is empty.
    sleep 0.1
  end
end
