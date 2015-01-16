#  ImapClient::Daemon - Main entry point for the IMAP client. Reads
#  credentials from a database, connects to IMAP servers, listens for
#  email, generates webhook events.
#
#  Contains load-balancing code so that when multiple ImapClient::Daemon
#  processes are running they claim users evenly. The ImapClient::Daemon
#  coordinate through the database.
#
#  Starts a few different types of threads:
#
#  + Heartbeat thread - Publishes our heartbeat to the database. Runs every 10 seconds.
#  + Discovery thread - Listen for the heartbeats of other ImapClient::Daemon processes. Runs every 30 seconds.
#  + Claim thread - Claims an even share of users. Runs every 30 seconds.
#  + Worker threads - A small pool of threads to run CPU intensive operations. (5 by default.)
#  + User threads - A list of threads created on demand to managed communication with IMAP server. (Limited to 500 by default.)

require 'net/imap'

class ImapClient::Daemon
  include Common::Stoppable
  include Common::WorkerPool
  include Common::LightSleep
  include Common::WrappedThread
  include Common::DbConnection
  include Common::CsvLog

  attr_accessor :stress_test_mode, :chaos_mode
  attr_accessor :num_worker_threads, :max_user_threads, :max_email_size, :tracer_interval, :num_tracers
  attr_accessor :server_tag, :server_rhash
  attr_accessor :heartbeat_thread, :discovery_thread
  attr_accessor :claim_thread, :user_threads, :error_counts
  attr_accessor :tracer_thread, :tracer_emails_processed
  attr_accessor :total_emails_processed, :processed_log

  def initialize(options = {})
    # Settings.
    self.stress_test_mode   = options.fetch(:stress_test_mode)
    self.chaos_mode         = options.fetch(:enable_chaos)
    self.num_worker_threads = options.fetch(:num_worker_threads)
    self.max_user_threads   = options.fetch(:max_user_threads)
    self.max_email_size     = options.fetch(:max_email_size)
    self.tracer_interval    = options.fetch(:tracer_interval)
    self.num_tracers        = options.fetch(:num_tracers)

    # Load balancing stuff.
    self.server_tag = SecureRandom.hex(10)
    self.server_rhash = ImapClient::RendezvousHash.new([])

    # User stuff.
    self.user_threads = {}
    self.error_counts = {}

    # Stats.
    self.total_emails_processed = 0
  end

  def run
    trap_signals
    force_class_loading

    # If stress testing, start a log.
    if self.stress_test_mode
      start_csv_log_thread
      self.processed_log = csv_log("./log/stress/processed_emails_#{server_tag}.csv")
    end

    # Start our threads.
    set_db_connection_pool_size(self.num_worker_threads + 4)
    start_worker_pool(num_worker_threads)
    start_heartbeat_thread
    start_discovery_thread
    start_claim_thread
    start_tracer_thread

    # Sleep until we are stopped.
    light_sleep
  rescue => e
    stop!
    Log.exception(e)
  ensure
    stop!
    heartbeat_thread && heartbeat_thread.terminate
    discovery_thread && discovery_thread.terminate
    claim_thread && claim_thread.terminate
    terminate_worker_pool
    user_threads.values.map(&:terminate)
    user_threads.values.map(&:join)
    close_csv_logs
  end


  # Public: Returns the number of errors for a user.
  def error_count(user_id)
    self.error_counts[user_id] ||= 0
  end

  # Public: Increment the error count for a user
  def increment_error_count(user_id)
    self.error_counts[user_id] ||= 0
    self.error_counts[user_id] += 1
  end

  # Public:
  def clear_error_count(user_id)
    self.error_counts[user_id] = 0
  end


  private


  def force_class_loading
    # Force ImapDaemonHeartbeat to load before we create any
    # threads. This fixes a "Circular dependency detected while
    # autoloading constant ImapDaemonHeartbeat" error.
    ImapDaemonHeartbeat
    CallNewMailWebhook
    self.error_counts = {}
  end

  def start_heartbeat_thread
    self.heartbeat_thread = wrapped_thread do
      establish_db_connection
      heartbeat_thread_runner
    end
  end

  def start_discovery_thread
    self.discovery_thread = wrapped_thread do
      establish_db_connection
      discovery_thread_runner
    end

    # Wait for servers.
    while running? && server_rhash.size == 0
      Log.info("Discovering other daemons...")
      light_sleep 1
    end
  end

  def start_claim_thread
    self.claim_thread = wrapped_thread do
      establish_db_connection
      claim_thread_runner
    end
  end

  def start_tracer_thread
    self.tracer_thread = wrapped_thread do
      establish_db_connection
      tracer_thread_runner
    end
  end

  # Private: Creates/updates an ImapDaemonHeartbeat record in the
  # database every 10 seconds.
  def heartbeat_thread_runner
    heartbeat = ImapDaemonHeartbeat.create(:tag => server_tag)
    while running?
      # Update the heartbeat.
      heartbeat.touch

      # Log Heroku / Librato stats.
      Log.librato(:measure, 'imap_client.thread.count', Thread.list.count)
      Log.librato(:measure, 'imap_client.work_queue.length', work_queue_length)
      Log.librato(:sample,  'imap_client.user_thread.count', user_threads.count)
      Log.librato(:sample,  'imap_client.total_emails_processed', total_emails_processed)

      light_sleep 10
    end
  end

  # Private: Fetches all recently updated ImapDaemonHeartbeat records
  # in the database very 30 seconds. Create a new RendezvousHash from
  # the associated tags.
  def discovery_thread_runner
    while running?
      tags = ImapDaemonHeartbeat.where("updated_at >= ?", 30.seconds.ago).map(&:tag)
      Log.info("There are #{tags.count} daemons running.")

      self.server_rhash = ImapClient::RendezvousHash.new(tags)

      if server_rhash.size == 0
        light_sleep 1
      else
        light_sleep 10
      end
    end
  end

  # Private: Iterate through users and schedule a connect or
  # disconnect task depending on whether the user is hashed to this
  # server.
  def claim_thread_runner
    while running?
      User.select(:id, :email, :connected_at, :archived).find_each do |user|
        if server_rhash.hash(user.id) == server_tag && !user.archived && user.connected_at
          schedule_work(:connect_user, :hash => user.id, :user_id => user.id)
        else
          schedule_work(:disconnect_user, :hash => user.id, :user_id => user.id)
        end
      end
      light_sleep 10
    end
  end

  # Private: Schedule a tracer emails to random tracer users.
  def tracer_thread_runner
    while running?
      # Get a random user assigned to this server.
      user = User.where(:enable_tracer => true, :archived => false).select(:id, :connected_at).all.select do |user|
        server_rhash.hash(user.id) == server_tag && user.connected_at
      end.shuffle.first

      # If we found a user, schedule a tracer email.
      if user
        user.reload
        ScheduleTracerEmails.new(user, self.num_tracers).delay.run
      end

      light_sleep self.tracer_interval
    end
  end

  # Private: Disconnect all user threads.
  def disconnect_all_users
    user_threads.keys.dup.each do |user_id|
      schedule_work(:disconnect_user, :hash => user_id, :user_id => user_id)
    end
  end

  # Private: Construct and return user thread options.
  def user_options
    @user_options ||= {
      :max_email_size => self.max_email_size
    }
  end

  # Private: Create a new user thread for the specified user.
  #
  # options[:user_id] - The user id.
  def action_connect_user(options)
    user_id = options[:user_id]

    # Nothing to do if stopped.
    return if stopping?

    # Are we allowed to create a new user thread?
    return if user_threads.count > max_user_threads

    # Nothing to do if already a thread.
    return if user_threads[user_id].present?

    # Load the user; preload connection information.
    user = User.find(user_id)
    user.connection.imap_provider

    # Start the thread.
    user_threads[user_id] = wrapped_thread do
      Log.info("Connecting #{user.email}...")
      ImapClient::UserThread.new(self, user, user_options).run
    end
  rescue => e
    Log.exception(e)
  end

  # Private: Disconnect a user and destroy the user thread.
  #
  # options[:user_id] - The user id.
  def action_disconnect_user(options)
    # Nothing to do if no thread.
    user_id = options[:user_id]
    return if user_threads[user_id].nil?

    # Tell the thread to stop.
    thread = user_threads.delete(user_id)
    thread.terminate
  rescue => e
    Log.exception(e)
  end

  # Private: Run a function, then restart a user thread.
  #
  # See UserThread#schedule for more details.
  #
  # options[:block] - The block to run.
  # options[:thread] - The thread to restart.
  def action_callback(options)
    options[:block].call
  rescue => e
    Log.exception(e)
  ensure
    options[:thread].run
  end
end
