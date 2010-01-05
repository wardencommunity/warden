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
      self[:default_serializers] ||= [ :session ]
    end

    # Do not raise an error if a missing strategy is given by default.
    # :api: plugin
    def silence_missing_strategies!
      self[:silence_missing_strategies] = true
    end

    def silence_missing_strategies? #:nodoc:
      !!self[:silence_missing_strategies]
    end

    # Do not raise an error if a missing serializer is given by default.
    # :api: plugin
    def silence_missing_serializers!
      self[:silence_missing_serializers] = true
    end

    def silence_missing_serializers? #:nodoc:
      !!self[:silence_missing_serializers]
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

    # Set the default serializers to use. By default, only session is enabled.
    # :api: public
    def default_serializers(*serializers)
      if serializers.empty?
        self[:default_serializers]
      else
        self[:default_serializers] = serializers.flatten
      end
    end

    # Quick accessor to strategies from manager
    # :api: public
    def serializers
      Warden::Serializers
    end

    # Quick accessor to strategies from manager
    # :api: public
    def strategies
      Warden::Strategies
    end
  end
end