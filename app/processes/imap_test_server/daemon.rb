require 'socket'

class ImapTestServer::Daemon
  include Common::Stoppable
  include Common::LightSleep
  include Common::WrappedThread

  attr_accessor :port
  attr_accessor :login_callback
  attr_accessor :connection_thread
  attr_accessor :sockets, :socket_states
  attr_accessor :mailboxes

  def initialize(options = {})
    self.port = (options[:port] || 143).to_i
    client_threads = []
  end

  # Add the given Mail object to a user's inbox.
  def add_mail(mail)
  end

  def run
    start_connection_thread
    start_chaos_monkey_thread
  ensure
    self.stop = true
    connection_thread && connection_thread.terminate
    sockets.map(&:close)
  end


  def start_connection_thread
    self.connection_thread = wrapped_thread do
      connection_thread_runner
    end
  end

  def connection_thread_runner
    server = TCPServer.new(1233)

    while !stop
      socket = server.accept
      self.socket_states[socket.hash] = {}
      self.sockets << socket
    end
  end

    end
    require 'socket'  # TCPServer
    loop {
      Thread.start(ss.accept) { |s|
        begin
          while line = s.gets;  # Returns nil on EOF.
            (s << "You wrote: #{line.inspect}\r\n").flush
          end
        rescue
          bt = $!.backtrace * "\n  "
          ($stderr << "error: #{$!.inspect}\n  #{bt}\n").flush
        ensure
          s.close
        end
      }
    }
  end

  private unless Rails.env.test?

end
