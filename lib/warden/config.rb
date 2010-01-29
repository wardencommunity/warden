# encoding: utf-8

module Warden
  # This is a class which is yielded on use Warden::Manager. If you have a plugin
  # and wants to add more configuration to warden, you just need to extend this
  # class.
  class Config < Hash
    # Creates an accessor that simply sets and reads a key in the hash:
    #
    #   class Config < Hash
    #     hash_accessor :failure_app
    #   end
    #
    #   config = Config.new
    #   config.failure_app = Foo
    #   config[:failure_app] #=> Foo
    #
    #   config[:failure_app] = Bar
    #   config.failure_app #=> Bar
    #
    def self.hash_accessor(*names) #:nodoc:
      names.each do |name|
        class_eval <<-METHOD, __FILE__, __LINE__ + 1
          def #{name}
            self[:#{name}]
          end

          def #{name}=(value)
            self[:#{name}] = value
          end
        METHOD
      end
    end

    hash_accessor :failure_app, :default_scope

    def initialize(other={})
      merge!(other)
      self[:default_scope]       ||= :default
      self[:default_strategies]  ||= []
    end

    # Do not raise an error if a missing strategy is given by default.
    # :api: plugin
    def silence_missing_strategies!
      self[:silence_missing_strategies] = true
    end

    def silence_missing_strategies? #:nodoc:
      !!self[:silence_missing_strategies]
    end

    # Set the default strategies to use.
    # :api: public
    def default_strategies(*strategies)
      if strategies.empty?
        self[:default_strategies]
      else
        self[:default_strategies] = strategies.flatten
      end
    end

    # Quick accessor to strategies from manager
    # :api: public
    def strategies
      Warden::Strategies
    end

    # Hook from configuration to serialize_into_session.
    # :api: public
    def serialize_into_session(*args, &block)
      Warden::Manager.serialize_into_session(*args, &block)
    end

    # Hook from configuration to serialize_from_session.
    # :api: public
    def serialize_from_session(*args, &block)
      Warden::Manager.serialize_from_session(*args, &block)
    end
  end
end