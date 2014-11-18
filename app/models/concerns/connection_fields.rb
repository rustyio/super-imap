module ConnectionFields
  extend ActiveSupport::Concern

  included do
    @connection_fields = []

    def self.connection_field(field, options = {})
      @connection_fields ||= []
      @connection_fields << field
      if options[:required]
        validates_presence_of(field)
      end
    end

    def self.connection_fields
      @connection_fields || []
    end

    def connection_fields
      self.class.connection_fields
    end
  end
end
