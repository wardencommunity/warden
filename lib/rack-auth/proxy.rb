module Rack
  module Auth
    class UserNotSet < RuntimeError; end

    class Proxy
      attr_accessor :winning_strategy
      attr_reader :env
      
      extend ::Forwardable
      include ::Rack::Auth::Mixins::Common
            
      def_delegators :winning_strategy, :headers, :message, :_status, :custom_response
      
      def initialize(env, config = {})
        @env = env
        @config = config
        @strategies = @config.fetch(:default, [])
        @users = {}
        errors # setup the error object in the session
      end
      
      def authenticated?(*args)
        scope = scope_from_args(args)
        _perform_authentication(*args)
        !user(scope).nil?
      end # authenticated?
      
      def authenticate(*args)
        _perform_authentication(*args)
        winning_strategy
      end
      
      def authenticate!(*args)
        scope = scope_from_args(args)
        _perform_authentication(*args)
        throw(:auth, :action => :unauthenticated) if !user(scope)
      end
      
      def set_user(user, opts = {})
        scope = opts.fetch(:scope, :default)
        Rack::Auth::Manager._store_user(user, session, scope) # Get the user into the session
        
        # Run the after hooks for setting the user
        Rack::Auth::Manager._after_set_user.each{|hook| hook.call(user, self, opts)}
        
        @users[scope] = user # Store the user in the proxy user object
      end

      def user(scope = :default)
        @users[scope]
      end
      
      # proxy methods through to the winning strategy
      def result; winning_strategy.nil? ? nil : winning_strategy.result; end
      
      private 
      def _perform_authentication(*args)
        scope = scope_from_args(args)
        opts = opts_from_args(args)
        # Look for an existing user in the session for this scope
        if @users[scope] || @users[scope] = Rack::Auth::Manager._fetch_user(session, scope)
          return @users[scope]
        end
        
        # If there was no user in the session.  See if we can get one from the request
        strategies = args.empty? ? @strategies : args
        raise "No Strategies Found" if strategies.empty?
        strategies.each do |s|
          result = Rack::Auth::Strategies[s].new(@env, @config)._run!
          self.winning_strategy = result 
          break if result.halted?
        end
        
        if winning_strategy.user
          set_user(winning_strategy.user, opts)
        
          # Run the after_authentication hooks
          Rack::Auth::Manager._after_authentication.each{|hook| hook.call(winning_strategy.user, self, opts)}
        end
        
        winning_strategy
      end
      
      def scope_from_args(args)
        Hash === args.last ? args.last.fetch(:scope, :default) : :default
      end
      
      def opts_from_args(args)
        Hash === args.last ? args.pop : {}
      end

    end # Proxy
  end # Auth
end # Rack
