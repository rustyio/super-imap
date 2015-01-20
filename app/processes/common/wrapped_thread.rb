module Common::WrappedThread
  def wrapped_thread(&block)
    Thread.new do
      begin
        yield
      rescue => e
        Log.exception(e)
      end
    end
  end
end
