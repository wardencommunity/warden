module Rack
  module Auth
    class UserNotSet < RuntimeError; end

    class Proxy
      attr_accessor :winning_strategy
      
      extend ::Forwardable
      include ::Rack::Auth::Mixins::Common
            
      def_delegators :winning_strategy, :headers, :message
      
      def initialize(env, config = {})
        @env = env
        @config = config
        @strategies = @config.fetch(:default, [])
        @users = {}
        errors # setup the error object in the session
      end
      
      def authenticated?(*args)
        !_perform_authentication(*args).user.nil?
      end # authenticated?
      
      def authenticate(*args)
        _perform_authentication(*args)
      end
      
      def authenticate!(*args)
        _perform_authentication(*args)
        throw(:unauthenticated, winning_strategy.status) if !winning_strategy.user
      end
      
      def set_user(user, opts = {})
        scope = opts.fetch(:scope, :default)
        Rack::Auth::Manager.store_user(user, scope, session) # Get the user into the session
        @users[scope] = user # Store the user in the proxy user object
      end

      def user(scope = :default)
        @users[scope]
      end
      
      def rack_response
        if winning_strategy
          winning_strategy.rack_response
        else
          [401,{"Content-Type" => "text/plain"}, "Authentication Required"]
        end
      end

      private 
      def _perform_authentication(*args)
        opts  = Hash === args.last ? args.pop : {}
        scope = opts.fetch(:scope, :default) 
        
        strategies = args.empty? ? @strategies : args
        raise "No Strategies Found" if strategies.empty?
        strategies.each do |s|
          result = Rack::Auth::Strategies[s].new(@env, @config)._run!
          self.winning_strategy = result
          break if result.halted?
        end
        set_user(winning_strategy.user, opts) unless winning_strategy.user.nil?
        winning_strategy
      end

    end # Proxy
  end # Auth
end # Rack
