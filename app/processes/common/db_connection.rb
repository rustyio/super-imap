module Common::DbConnection
  def db_config
    ActiveRecord::Base.configurations[Rails.env] ||
      Rails.application.config.database_configuration[Rails.env]
  end

  def set_db_connection_pool_size(size)
    ActiveRecord::Base.connection_pool.disconnect!
    ActiveSupport.on_load(:active_record) do
      config = ActiveRecord::Base.configurations[Rails.env] ||
               Rails.application.config.database_configuration[Rails.env]
      config['pool'] = size
      ActiveRecord::Base.establish_connection(config)
    end
  end
end
