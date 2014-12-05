# coding: utf-8
module ConnectionFields
  extend ActiveSupport::Concern

  included do
    @connection_fields = []

    def self.connection_field(field, options = {})
      @connection_fields ||= []
      @connection_fields << field

      # Maybe validate presence.
      if options[:required]
        validates_presence_of(field)
      end

      # Maybe obscure the actual value.
      if options[:secure]
        define_method(field) do |secure = true|
          if secure && self[field].present?
            self[field][0..3] + ("•" * (self[field].length - 4))
          else
            super()
          end
        end

        define_method("#{field}=".to_sym) do |value|
          if value != self.send(field)
            super(value)
          end
        end
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
