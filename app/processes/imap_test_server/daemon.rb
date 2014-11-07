#  ImapTestServer::Daemon - A test IMAP server that can respond to all
#  calls made by the ImapClient process. Generates test data and
#  (muhahaha) deliberately responds to some calls with gibberish in
#  order to test how well ImapClient recovers.
#
#  The daemon has three threads:
#  + The Connection thread listens for incoming connections.
#  + The New Mail thread generates new emails to users.
#  + The Process Sockets (main) thread sits in a tight loop, sending and receiving IMAP commands.
#
#  The code is organized as follows:
#
#  + The Daemon class contains high level connection logic.
#  + SocketState holds the state of a socket and contains our IMAP logic.
#  + Mailboxes holds mail for all users.

require 'socket'

class ImapTestServer::Daemon
  include Common::Stoppable
  include Common::LightSleep
  include Common::WrappedThread
  include Common::DbConnection

  attr_accessor :port
  attr_accessor :stats_thread
  attr_accessor :connection_thread
  attr_accessor :new_sockets, :sockets, :socket_states
  attr_accessor :mailboxes, :emails_per_minute

  def initialize(options = {})
    self.port = (options[:port] || 10143).to_i
    self.new_sockets = Queue.new
    self.sockets = []
    self.socket_states = {}
    self.mailboxes = Mailboxes.new()
    self.emails_per_minute = 60
  end

  # Public: Start threads and begin servicing connections.
  def run
    trap_signals
    start_stats_thread
    start_connection_thread
    start_new_mail_thread
    process_sockets
  rescue => e
    Log.exception(e)
    stop!
    raise e
  ensure
    connection_thread && connection_thread.terminate
    sockets.map(&:close)
  end

  private

  def start_stats_thread
    self.stats_thread = wrapped_thread do
      establish_db_connection
      stats_thread_runner
    end
  end

  def start_connection_thread
    self.connection_thread = wrapped_thread do
      establish_db_connection
      connection_thread_runner
    end
  end

  def start_new_mail_thread
    self.connection_thread = wrapped_thread do
      establish_db_connection
      new_mail_thread_runner
    end
  end

  def stats_thread_runner
    while running?
      Log.info("Managing #{sockets.count} connections.")
      light_sleep 10
    end
  end

  # Private: Accepts incoming connections.
  def connection_thread_runner
    Log.info("Waiting for connections on port 127.0.0.1:#{port}.")
    server = TCPServer.new("127.0.0.1", port)
    while running?
      begin
        socket = server.accept_nonblock
        new_sockets << socket
      rescue IO::EAGAINWaitReadable
        sleep 0.2
      end
    end
  end

  # Private: Sends and receives IMAP commands.
  def process_sockets
    while running?
      process_new_sockets
      process_incoming_messages
      send_exists_messages
      sleep 0.1
    end
  end

  def process_new_sockets
    while running? && !new_sockets.empty?
      socket = new_sockets.pop(true)
      process_new_socket(socket)
    end
  end

  def process_incoming_messages
    # Which sockets need attention?
    response = IO.select(sockets, [], [], 0)
    return if response.nil?

    # Attend to the sockets.
    read_sockets, _, _ = response
    read_sockets.each do |socket|
      process_incoming_message(socket)
    end
  end

  def send_exists_messages
    socket_states.values.each do |socket_state|
      socket_state.send_exists_messages
    end
  end

  def process_new_socket(socket)
    socket_state = ImapTestServer::SocketState.new(self.mailboxes, socket)
    socket_state.handle_connect

    # Add to our list of existing sockets.
    self.sockets << socket
    self.socket_states[socket.hash] = socket_state
  rescue => e
    Log.exception(e)
    close_socket(socket)
  end

  def process_incoming_message(socket)
    command = socket.gets
    if command.present?
      socket_state = socket_states[socket.hash]
      socket_state.handle_command(command)
    else
      close_socket(socket)
    end
  rescue ImapTestServer::SocketState::NormalDisconnect => e
    close_socket(socket)
  rescue ImapTestServer::SocketState::ChaosDisconnect => e
    close_socket(socket)
  rescue => e
    Log.exception(e)
    close_socket(socket)
  end

  def close_socket(socket)
    sockets.delete(socket)
    socket_states.delete(socket.hash)
    socket.close()
  rescue => e
    Log.exception(e)
  end

  def new_mail_thread_runner
    sleep_seconds = 5

    while running?
      if self.mailboxes.count > 0
        n = (1.0 * sleep_seconds / 60) * emails_per_minute
        generate_new_mail(n)
      end
      light_sleep sleep_seconds
    end
  end

  def generate_new_mail(n)
    # What's our chance of generating an email for an individual user?
    prob_of_email = n / self.mailboxes.count

    self.mailboxes.each do |mailbox|
      if rand() < prob_of_email
        mailbox.add_fake_message
      end
    end
  end
end
