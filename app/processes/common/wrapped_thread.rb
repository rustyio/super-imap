module Common::WrappedThread
  include Common::Stoppable

  def wrapped_thread(&block)
    Thread.new do
      begin
        yield
      rescue => e
        Log.exception(e)
        stop!
      end
    end
  rescue => e
    Log.exception(e)
    stop!
  end
end
