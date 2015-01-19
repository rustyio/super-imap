# coding: utf-8
module ConnectionFields
  extend ActiveSupport::Concern

  included do
    @connection_fields = []

    def self.encrypt(value)
      Rails.application.config.encryption_cipher ? Rails.application.config.encryption_cipher.encrypt(value) : value
    end

    def self.decrypt(value)
      begin
        Rails.application.config.encryption_cipher ? Rails.application.config.encryption_cipher.decrypt(value) : value
      rescue
        value
      end
    end

    def self.connection_field(field, options = {})
      @connection_fields ||= []
      @connection_fields << field

      # Maybe validate presence.
      if options[:required]
        validates_presence_of(field)
      end

      # Maybe obscure the actual value.
      if options[:secure]
        define_method(field) do |secure = false|
          if !secure && self[field].present?
            "- encrypted -"
          else
            self.class.decrypt(super())
          end
        end

        define_method("#{field}_secure".to_sym) do
          self.send(field, true)
        end

        define_method("#{field}=".to_sym) do |value|
          if value != self.send(field)
            super(self.class.encrypt(value))
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
