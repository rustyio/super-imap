module Common::DbConnection
  def db_config
    ActiveRecord::Base.configurations[Rails.env] ||
      Rails.application.config.database_configuration[Rails.env]
  end

  def set_db_connection_pool_size(size)
    db_config['pool'] = size
  end

  def establish_db_connection
    # Get the connection.
    conn = ActiveRecord::Base.establish_connection

    # Ensure we can successfully connected.
    while running?
      begin
        conn.connection.execute("SELECT 1")
        break if conn.connected?
      rescue => e
        sleep 1
      end
    end
  end
end
