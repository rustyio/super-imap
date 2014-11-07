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

  attr_accessor :num_worker_threads, :max_user_threads, :max_email_size
  attr_accessor :server_tag, :server_rhash
  attr_accessor :heartbeat_thread, :discovery_thread
  attr_accessor :claim_thread, :user_threads

  def initialize(options = {})
    # Settings.
    self.num_worker_threads = options[:num_worker_threads] || 5
    self.max_user_threads   = options[:max_user_threads]   || 500
    self.max_email_size     = options[:max_email_size]     || 1024 * 1024

    # Load balancing stuff.
    self.server_tag = SecureRandom.hex(10)
    self.server_rhash = ImapClient::RendezvousHash.new([])

    # User stuff.
    self.user_threads = {}
  end

  def run
    trap_signals
    force_class_loading

    # Start our threads.
    set_db_connection_pool_size(self.num_worker_threads + 3)
    start_worker_pool(num_worker_threads)
    start_heartbeat_thread
    start_discovery_thread
    start_claim_thread

    # Sleep until we are stopped.
    light_sleep
  rescue => e
    Log.exception(e)
    stop!
    raise e
  ensure
    heartbeat_thread && heartbeat_thread.terminate
    discovery_thread && discovery_thread.terminate
    claim_thread && claim_thread.terminate
    disconnect_all_users
    wait_for_worker_pool
  end


  private


  def force_class_loading
    # Force ImapDaemonHeartbeat to load before we create any
    # threads. This fixes a "Circular dependency detected while
    # autoloading constant ImapDaemonHeartbeat" error.
    ImapDaemonHeartbeat
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

  # Private: Creates/updates an ImapDaemonHeartbeat record in the
  # database every 10 seconds.
  def heartbeat_thread_runner
    heartbeat = ImapDaemonHeartbeat.create(:tag => server_tag)
    while running?
      Log.info("Heartbeat (server_tag = #{server_tag}, work_queue = #{work_queue_length}, user_threads = #{user_threads.count}).")
      heartbeat.touch
      light_sleep 10
    end
  end

  # Private: Fetches all recently updated ImapDaemonHeartbeat records
  # in the database very 30 seconds. Create a new RendezvousHash from
  # the associated tags.
  def discovery_thread_runner
    while !stop
      tags = ImapDaemonHeartbeat.where("updated_at >= ?", 30.seconds.ago).map(&:tag)
      Log.info("There are #{tags.count} daemons running.")

      self.server_rhash = ImapClient::RendezvousHash.new(tags)

      if server_rhash.size == 0
        light_sleep 1
      else
        light_sleep 30
      end
    end
  end

  # Private: Iterate through users and schedule a connect or
  # disconnect task depending on whether the user is hashed to this
  # server.
  def claim_thread_runner
    while !stop
      User.select(:id, :email).find_each do |user|
        if server_rhash.hash(user.id) == server_tag
          schedule_work(:connect_user, :hash => user.id, :user_id => user.id)
        else
          schedule_work(:disconnect_user, :hash => user.id, :user_id => user.id)
        end
      end
      light_sleep 30
    end
  end

  # Private: Disconnect all user threads.
  def disconnect_all_users
    user_threads.keys.each do |user_id|
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
    Log.info("action_connect_user")

    user_id = options[:user_id]

    # Nothing to do if stopped.
    return if stopping?

    # Nothing to do if already a thread.
    return if user_threads[user_id].present?

    # Are we allowed to create a new user thread?
    return if user_threads.count >= max_user_threads

    # Load the user; preload connection information.
    user = User.find(user_id)
    user.connection.connection_type

    # Start the thread.
    user_threads[user_id] = wrapped_thread do
      ImapClient::UserThread.new(self, user, user_options).run
    end
  end

  # Private: Disconnect a user and destroy the user thread.
  #
  # options[:user_id] - The user id.
  def action_disconnect_user(options)
    Log.info("action_disconnect_user")

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
  rescue => e
    Log.exception(e)
  ensure
    Log.info("Continuing Thread")
    options[:thread].run
  end
end
