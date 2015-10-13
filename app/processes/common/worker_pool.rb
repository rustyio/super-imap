module Common::WorkerPool
  include Common::Stoppable
  include Common::WrappedThread
  include Common::DbConnection

  attr_accessor :worker_rhash
  attr_accessor :work_queues, :work_queues_lock
  attr_accessor :worker_threads, :worker_threads_lock
  attr_accessor :work_queue_latency

  def init_worker_pool
    self.work_queues = []
    self.work_queues_lock = Mutex.new
    self.worker_threads = []
    self.worker_threads_lock = Mutex.new
    self.worker_rhash = ImapClient::RendezvousHash.new
  end

  # Public: Start a number of worker threads and begin processing
  # scheduled work.
  def start_worker_pool(num_worker_threads)
    # Create work queues.
    work_queues_lock.synchronize do
      worker_threads_lock.synchronize do
        num_worker_threads.times do |n|
          work_queue = Queue.new
          worker_thread = _start_worker_thread(work_queue)
          self.work_queues << work_queue
          self.worker_threads << worker_thread
        end
      end
    end

    tags = num_worker_threads.times.map(&:to_i)
    self.worker_rhash.site_tags = tags
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
    index = worker_rhash.hash(options[:hash])
    options.merge!(:'$action' => s, :'$time' => Time.now)
    work_queues_lock.synchronize do
      work_queues[index] << options
    end
  end

  # Public: Return the total number of scheduled items in the work queue.
  def work_queue_length
    work_queues_lock.synchronize do
      work_queues.map(&:size).inject(&:+)
    end
  end

  # Public: Wait for the worker pool to finish processing all items.
  def terminate_worker_pool
    Log.info("Waiting for worker threads...")
    worker_threads_lock.synchronize do
      worker_threads.present? && worker_threads.map(&:terminate)
    end
  end

  private

  def _start_worker_thread(work_queue)
    wrapped_thread do
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        _worker_thread_runner(work_queue)
      end
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
