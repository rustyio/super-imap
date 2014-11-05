module Common::WrappedThread
  def wrapped_thread(&block)
    Thread.new do
      begin
        yield
      rescue => e
        Log.exception(e)
        self.stop = true
      end
    end
  rescue => e
    print e
    Log.exception(e)
    self.stop = true
  end
end
