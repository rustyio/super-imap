module Common::DbConnection
  def db_config
    ActiveRecord::Base.configurations[Rails.env] ||
      Rails.application.config.database_configuration[Rails.env]
  end

  def set_db_connection_pool_size(size)
    db_config['pool'] = size
  end

  def establish_db_connection
    ActiveRecord::Base.establish_connection
    sleep 2
  end
end
