module Common::WorkerPool
  include Common::Stoppable
  include Common::WrappedThread
  include Common::DbConnection

  attr_accessor :work_queues, :worker_rhash, :worker_threads

  # Public: Start a number of worker threads and begin processing
  # scheduled work.
  def start_worker_pool(num_worker_threads)
    # Worker stuff.
    self.work_queues = []
    self.worker_threads = []
    self.worker_rhash = ImapClient::RendezvousHash.new([])

    # Start worker threads.
    num_worker_threads.times do |n|
      _start_worker_thread
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
    index = worker_rhash.hash(options[:hash] || rand())
    options.merge!(:'$action' => s, :'$time' => Time.now)
    work_queues[index] << options
  end

  # Public: Return the total number of scheduled items in the work queue.
  def work_queue_length
    work_queues.map(&:size).inject(&:+)
  end

  # Public: Wait for the worker pool to finish processing all items.
  def wait_for_worker_pool
    worker_threads && worker_threads.map(&:join)
  end

  private

  def _start_worker_thread
    self.worker_threads << wrapped_thread do
      establish_db_connection
      _worker_thread_runner
    end
  end

  def _worker_thread_runner
    # Create a work queue.
    work_queue = Queue.new
    self.work_queues << work_queue

    # Create the thread.
    while options = work_queue.pop()
      method = "action_#{options[:'$action']}".to_sym
      self.send(method.to_sym, options)
    end
  end
end
