module Rack
  module Auth
    class UserNotSet < RuntimeError; end

    class Proxy
      # :api: private
      attr_accessor :winning_strategy
      
      # An accessor to the rack env hash
      # :api: public
      attr_reader :env
      
      extend ::Forwardable
      include ::Rack::Auth::Mixins::Common
            
      # :api: private
      def_delegators :winning_strategy, :headers, :message, :_status, :custom_response

      def initialize(env, config = {}) # :nodoc:
        @env = env
        @config = config
        @strategies = @config.fetch(:default, [])
        @users = {}
        errors # setup the error object in the session
      end

      # Check to see if there is an authenticated user for the given scope.
      # When scope is not specified, :default is assumed.
      # 
      # Parameters: 
      #   args - a list of symbols (labels) that name the strategies to attempt
      #   opts - an options hash that contains the :scope of the user to check
      #
      # Example: 
      #   env['rack-auth'].authenticated?(:password, :scope => :admin)
      # :api: public
      def authenticated?(*args)
        scope = scope_from_args(args)
        _perform_authentication(*args)
        !user(scope).nil?
      end # authenticated?
      
      # Run the authentiation strategies for the given strategies.  
      # If there is already a user logged in for a given scope, the strategies are not run
      # This does not halt the flow of control and is a passive attempt to authenticate only
      # When scope is not specified, :default is assumed.
      # 
      # Parameters: 
      #   args - a list of symbols (labels) that name the strategies to attempt
      #   opts - an options hash that contains the :scope of the user to check
      #
      # Example:
      #   env['auth'].authenticate(:password, :basic, :scope => :sudo)
      # :api: public
      def authenticate(*args)
        _perform_authentication(*args)
        winning_strategy
      end
      
      # The same as +authenticate+ except on failure it will throw an :auth symbol causing the request to be halted
      # and rendered through the +failure_app+
      # 
      # Example 
      #   env['rack-auth'].authenticate!(:password, :scope => :publisher) # throws if it cannot authenticate
      #
      # :api: public
      def authenticate!(*args)
        scope = scope_from_args(args)
        _perform_authentication(*args)
        throw(:auth, :action => :unauthenticated) if !user(scope)
      end
      
      # Manually set the user into the session and auth proxy
      # 
      # Parameters:
      #   user - An object that has been setup to serialize into and out of the session.
      #   opts - An options hash.  Use the :scope option to set the scope of the user
      # :api: public
      def set_user(user, opts = {})
        scope = (opts[:scope] ||= :default)
        Rack::Auth::Manager._store_user(user, session, scope) # Get the user into the session
        
        # Run the after hooks for setting the user
        Rack::Auth::Manager._after_set_user.each{|hook| hook.call(user, self, opts)}
        
        @users[scope] = user # Store the user in the proxy user object
      end
      
      # Provides acccess to the user object in a given scope for a request.
      # will be nil if not logged in
      # 
      # Example:
      #   # without scope (default user)
      #   env['rack-auth'].user
      #
      #   # with scope 
      #   env['rack-auth'].user(:admin)
      #
      # :api: public
      def user(scope = :default)
        @users[scope]
      end
      
      # Provides a scoped data repository for authenticated users.
      # Rack::Auth manages clearing out this data when a user logs out
      #
      # Example
      #  # default scope
      #  env['rack-auth'].data[:foo] = "bar"
      #
      #  # :sudo scope
      #  env['rack-auth'].data(:sudo)[:foo] = "bar"
      #
      # :api: public
      def data(scope = :default)
        raise NotAuthenticated, "#{scope.inspect} user is not logged in" unless authenticated?(:scope => scope)
        session["rack-auth.user.#{scope}.data"] ||= {}
      end
      
      # Provides logout functionality. 
      # The logout also manages any authenticated data storage and clears it when a user logs out.
      #
      # Parameters:
      #   scopes - a list of scopes to logout
      #
      # Example:
      #  # Logout everyone and clear the session
      #  env['rack-auth'].logout
      #
      #  # Logout the default user but leave the rest of the session alone
      #  env['rack-auth'].logout(:default)
      #
      #  # Logout the :publisher and :admin user
      #  env['rack-auth'].logout(:publisher, :admin)
      # 
      # :api: public
      def logout(*scopes)
        if scopes.empty?
          session.clear
        else
          scopes.each do |s|
            session["rack-auth.user.#{s}.key"] = nil
            session["rack-auth.user.#{s}.data"] = nil
          end
        end
      end
      
      # proxy methods through to the winning strategy
      # :api: private
      def result # :nodoc: 
         winning_strategy.nil? ? nil : winning_strategy.result
      end
      
      private 
      # :api: private
      def _perform_authentication(*args)
        scope = scope_from_args(args)
        opts = opts_from_args(args)
        # Look for an existing user in the session for this scope
        if @users[scope] || set_user(Rack::Auth::Manager._fetch_user(session, scope), :scope => scope)
          return @users[scope]
        end
        
        # If there was no user in the session.  See if we can get one from the request
        strategies = args.empty? ? @strategies : args
        raise "No Strategies Found" if strategies.empty? || !(strategies - Rack::Auth::Strategies._strategies.keys).empty?
        strategies.each do |s|
          strategy = Rack::Auth::Strategies[s].new(@env, @conf)
          next unless strategy.valid?
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
      
      # :api: private
      def scope_from_args(args)
        Hash === args.last ? args.last.fetch(:scope, :default) : :default
      end
      
      # :api: private
      def opts_from_args(args)
        Hash === args.last ? args.pop : {}
      end

    end # Proxy
  end # Auth
end # Rack
