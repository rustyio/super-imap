#  IMAP::Daemon - Main entry point for the server-side code. Reads
#  credentials from a database, connects to IMAP servers, listens for
#  email, generates webhook events.
#
#  Contains load-balancing code so that when multiple IMAP::Daemon
#  processes are running they claim users evenly. The IMAP::Daemon
#  coordinate through the database.
#
#  Starts a few different types of threads:
#
#  + Heartbeat thread - Publishes our heartbeat to the database. Runs every 10 seconds.
#  + Discovery thread - Listen for the heartbeats of other IMAP::Daemon processes. Runs every 30 seconds.
#  + Claim thread - Claims an even share of users. Runs every 30 seconds.
#  + Worker threads - A small pool of threads to run CPU intensive operations. (5 by default.)
#  + User threads - A list of threads created on demand to managed communication with IMAP server. (Limited to 500 by default.)

require 'net/imap'

class IMAP::Daemon
  attr_accessor :num_worker_threads, :num_user_threads
  attr_accessor :server_tag, :server_rhash
  attr_accessor :heartbeat, :heartbeat_thread, :discovery_thread
  attr_accessor :work_queue, :work_queue_rhash, :worker_threads
  attr_accessor :user_threads
  attr_accessor :stop

  def initialize(options = {})
    self.stop = false

    # Settings.
    self.num_worker_threads = options[:num_worker_threads] || 5
    self.max_user_threads   = options[:max_user_threads]   || 500
    self.max_email_size     = options[:max_email_size]     || 1024 * 1024

    # Load balancing stuff.
    self.server_tag = SecureRandom.hex(10)
    self.server_rhash = RendezvousHash.new([])

    # Worker stuff.
    self.work_queues = []
    self.worker_threads = []
    self.worker_hash = RendezvousHash.new([])
  end

  def run
    Signal.trap("INT") do stop = true end
    Signal.trap("TERM") do stop = true end

    # Start worker threads.
    num_worker_thread.times do |n|
      start_worker_thread(queue)
    end
    tags = worker_threads.length.times.map(&:to_i)
    work_queue_rhash = RendezvousHash.new(tags)

    # Start cross-daemon coordination threads.
    start_heartbeat_thread
    start_discovery_thread
    start_claim_thread

    while !stop
      sleep 1
    end
  ensure
    @stop = true
    heartbeat_thread.terminate
    discovery_thread.terminate
    claim_thread.terminate
    disconnect_all_users
  end

  # Public: Schedule a task to be executed on one of the work
  # queues.
  def schedule_work(s, options)
    # Ensure that work for a user consistently goes to the same
    # queue. This helps avoid tricky thread safety issues.
    object_tag = options[:user_id]
    index = work_queue_rhash.hash(object_tag)

    # Schedule the work.
    work_queues[index] << options.merge(:action => s, :time => Time.now)
  end

  private unless Rails.env.test?

  # Private: Start a thread that creates/updates an
  # ImapDaemonHeartbeat record in the database every 10 seconds.
  def start_heartbeat_thread
    self.heartbeat = ImapDaemonHeartbeat.create(:tag => server_tag)
    self.heartbeat_thread = Thread.new do
      while !stop
        log.info("Heartbeat (server_tag = #{server_tag}, work_queue = #{work_queue.length}, user_threads = #{user_threads.count}).")
        heartbeat.touch
        sleep 10
      end
    end
    self.heartbeat_thread.run
  end

  # Private: Start a thread that fetches all recently updated
  # ImapDaemonHeartbeat records in the database very 30
  # seconds. Create a new RendezvousHash from the associated tags.
  def start_discovery_thread
    self.discovery_thread = Thread.new do
      while !stop
        tags = ImapDaemonHeartbeat.where(:updated_at > 30.seconds.ago).map(&:tag)
        self.server_rhash = RendezvousHash.new(tags)
        sleep 30
      end
    end
  end

  # Private: Every 30 seconds, iterate through users and schedule a
  # connect or disconnect task depending on whether the user is hashed
  # to this server.
  def start_claim_thread
    self.claim_thread = Thread.new do
      while !stop
        User.find_each do |user|
          if rhash.hash(user.id) == server_tag
            schedule_work("connect_user", :user_id => user.id)
          else
            schedule_work("disconnect_user", :user_id => user.id)
          end
        end
        sleep 30
      end
    end
  end

  # Private: Create a worker thread with a private work queue.
  def start_worker_thread
    # Create a work queue.
    work_queue = Queue.new
    self.work_queues << work_queues

    # Create the thread.
    self.worker_threads << Thread.new do
      while options = work_queue.pop()
        method = "action_#{options[:action]}".to_sym
        self.send(method.to_sym, options)
      end
    end
  end

  # Private: Construct and return user thread options.
  def user_options
    @user_options ||= {
      :max_email_size = self.max_email_size
    }
  end

  # Private: Create a new user thread for the specified user.
  #
  # options[:user_id] - The user id.
  def action_connect_user(options)
    id = options[:user_id]

    # Nothing to do if stopped.
    return if stop

    # Nothing to do if already a thread.
    return if user_threads[id].present?

    # Are we allowed to create a new user thread?
    return if user_threads.count >= max_user_threads

    # Start the thread.
    user_threads << Thread.new do
      UserThread.new(self, id, user_options).run
    end
  end

  # Private: Disconnect a user and destroy the user thread.
  #
  # options[:user_id] - The user id.
  def action_disconnect_user(options)
    id = options[:user_id]

    # Nothing to do if no thread.
    return if user_threads[id].nil?

    # Tell the thread to stop.
    thread = user_threads.delete(id)
    thread.terminate
  end

  # Private: Run a function, then restart a user thread.
  #
  # See UserThread#schedule for more details.
  #
  # options[:block] - The block to run.
  # options[:thread] - The thread to restart.
  def action_callback(options)
    options[:block].call
    options[:thread].run
  end
end
