# encoding: utf-8
module Warden
  class UserNotSet < RuntimeError; end

  class Proxy
    # An accessor to the wining strategy
    # :api: private
    attr_accessor :winning_strategy

    # An accessor to the rack env hash
    # :api: public
    attr_reader :env

    extend ::Forwardable
    include ::Warden::Mixins::Common

    # :api: private
    def_delegators :winning_strategy, :headers, :_status, :custom_response

    def initialize(env, config = {}) #:nodoc:
      @env = env
      @config = config
      @strategies = @config.fetch(:default_strategies, [])
      @users = {}
      errors # setup the error object in the session
    end

    # Check to see if there is an authenticated user for the given scope.
    # When scope is not specified, Warden::Manager.default_scope is assumed.
    # This will not try to reconstitute the user from the session and will simply check for the
    # existance of a session key
    #
    # Parameters:
    #   scope - the scope to check for authentication.  Defaults to :default
    #
    # Example:
    #   env['warden'].authenticated?(:admin)
    #
    # :api: public
    def authenticated?(scope = Warden::Manager.default_scope)
      result = !!user(scope)
      yield if block_given? && result
      result
    end

    # Same API as authenticated, but returns false when authenticated.
    # :api: public
    def unauthenticated?(scope = Warden::Manager.default_scope)
      result = !authenticated?(scope)
      yield if block_given? && result
      result
    end

    # Run the authentiation strategies for the given strategies.
    # If there is already a user logged in for a given scope, the strategies are not run
    # This does not halt the flow of control and is a passive attempt to authenticate only
    # When scope is not specified, Warden::Manager.default_scope is assumed.
    #
    # Parameters:
    #   args - a list of symbols (labels) that name the strategies to attempt
    #   opts - an options hash that contains the :scope of the user to check
    #
    # Example:
    #   env['auth'].authenticate(:password, :basic, :scope => :sudo)
    #
    # :api: public
    def authenticate(*args)
      scope, opts = _perform_authentication(*args)
      user(scope)
    end

    # The same as +authenticate+ except on failure it will throw an :warden symbol causing the request to be halted
    # and rendered through the +failure_app+
    #
    # Example
    #   env['warden'].authenticate!(:password, :scope => :publisher) # throws if it cannot authenticate
    #
    # :api: public
    def authenticate!(*args)
      scope, opts = _perform_authentication(*args)
      throw(:warden, opts.merge(:action => :unauthenticated)) if !user(scope)
      user(scope)
    end

    # Checks if the given scope is stored in session. Different from authenticated?, this method
    # does not serialize values from session.
    #
    # Example
    #   env['warden'].set_user(@user)
    #   env['warden'].stored?                     #=> true
    #   env['warden'].stored?(:default)           #=> true
    #   env['warden'].stored?(:default, :session) #=> true
    #   env['warden'].stored?(:default, :cookie)  #=> false
    # 
    # :api: public
    def stored?(scope = Warden::Manager.default_scope, serializer = nil)
      if serializer
        find_serializer(serializer).stored?(scope)
      else
        serializers.any? { |s| s.stored?(scope) }
      end
    end

    # Manually set the user into the session and auth proxy
    #
    # Parameters:
    #   user - An object that has been setup to serialize into and out of the session.
    #   opts - An options hash.  Use the :scope option to set the scope of the user, set the :store option to false to skip serializing into the session.
    #
    # :api: public
    def set_user(user, opts = {})
      scope = (opts[:scope] ||= Warden::Manager.default_scope)
      _store_user(user, scope) unless opts[:store] == false
      @users[scope] = user

      # Run the after hooks for setting the user
      Warden::Manager._after_set_user.each{ |hook| hook.call(user, self, opts) }
      user
    end

    # Provides acccess to the user object in a given scope for a request.
    # will be nil if not logged in
    #
    # Example:
    #   # without scope (default user)
    #   env['warden'].user
    #
    #   # with scope
    #   env['warden'].user(:admin)
    #
    # :api: public
    def user(scope = Warden::Manager.default_scope)
      @users[scope] ||= set_user(_fetch_user(scope), :scope => scope)
    end

    # Provides a scoped session data for authenticated users.
    # Warden manages clearing out this data when a user logs out
    #
    # Example
    #  # default scope
    #  env['warden'].session[:foo] = "bar"
    #
    #  # :sudo scope
    #  env['warden'].session(:sudo)[:foo] = "bar"
    #
    # :api: public
    def session(scope = Warden::Manager.default_scope)
      raise NotAuthenticated, "#{scope.inspect} user is not logged in" unless authenticated?(scope)
      raw_session["warden.user.#{scope}.session"] ||= {}
    end

    # Provides logout functionality.
    # The logout also manages any authenticated data storage and clears it when a user logs out.
    #
    # Parameters:
    #   scopes - a list of scopes to logout
    #
    # Example:
    #  # Logout everyone and clear the session
    #  env['warden'].logout
    #
    #  # Logout the default user but leave the rest of the session alone
    #  env['warden'].logout(:default)
    #
    #  # Logout the :publisher and :admin user
    #  env['warden'].logout(:publisher, :admin)
    #
    # :api: public
    def logout(*scopes)
      if scopes.empty?
        scopes = @users.keys
        reset_session = true
      end

      scopes.each do |scope|
        user = @users.delete(scope)
        Warden::Manager._before_logout.each { |hook| hook.call(user, self, scope) }

        raw_session.delete("warden.user.#{scope}.session")
        _delete_user(user, scope)
      end

      reset_session! if reset_session
    end

    # proxy methods through to the winning strategy
    # :api: private
    def result # :nodoc:
      winning_strategy && winning_strategy.result
    end

    # Proxy through to the authentication strategy to find out the message that was generated.
    # :api: public
    def message
      winning_strategy && winning_strategy.message
    end

    # Provides a way to return a 401 without warden defering to the failure app
    # The result is a direct passthrough of your own response
    # :api: public
    def custom_failure!
      @custom_failure = true
    end

    # Check to see if the custom failur flag has been set
    # :api: public
    def custom_failure?
      !!@custom_failure
    end

    # Retrieve and initializer serializers.
    # :api: private
    def serializers # :nodoc:
      @serializers ||= begin
        array = []
        @config[:default_serializers].each do |s|
          unless Warden::Serializers[s]
            raise "Invalid serializer #{s}" unless silence_missing_serializers?
            next
          end
          array << Warden::Serializers[s].new(@env)
        end
        array
      end
    end

    private

    # :api: private
    def _perform_authentication(*args)
      scope = scope_from_args(args)
      opts = opts_from_args(args)

      # Look for an existing user in the session for this scope
      # If there was no user in the session.  See if we can get one from the request
      return scope, opts if the_user = user(scope)

      strategies = args.empty? ? @strategies : args
      raise "No Strategies Found" if strategies.empty?

      strategies.each do |s|
        unless Warden::Strategies[s]
          raise "Invalid strategy #{s}" unless args.empty? && silence_missing_strategies?
          next
        end

        strategy = Warden::Strategies[s].new(@env, scope)
        self.winning_strategy = strategy
        next unless strategy.valid?

        strategy._run!
        break if strategy.halted?
      end

      if winning_strategy && winning_strategy.user
        set_user(winning_strategy.user, opts)

        # Run the after_authentication hooks
        Warden::Manager._after_authentication.each{|hook| hook.call(winning_strategy.user, self, opts)}
      end

      [scope, opts]
    end

    # :api: private
    def scope_from_args(args) # :nodoc:
      Hash === args.last ? args.last.fetch(:scope, Warden::Manager.default_scope) : Warden::Manager.default_scope
    end

    # :api: private
    def opts_from_args(args) # :nodoc:
      Hash === args.last ? args.pop : {}
    end

    # :api: private
    def silence_missing_strategies? # :nodoc:
      @config[:silence_missing_strategies]
    end
    
    # :api: private
    def silence_missing_serializers? # :nodoc:
      @config[:silence_missing_serializers]
    end

    # Does the work of storing the user in stores.
    # :api: private
    def _store_user(user, scope = Warden::Manager.default_scope) # :nodoc:
      return unless user
      serializers.each { |s| s.store(user, scope) }
    end

    # Does the work of fetching the user from the first store.
    # :api: private
    def _fetch_user(scope = Warden::Manager.default_scope) # :nodoc:
      serializers.each do |s|
        user = s.fetch(scope)
        return user if user
      end
      nil
    end

    # Does the work of deleteing the user in all stores.
    # :api: private
    def _delete_user(user, scope = Warden::Manager.default_scope) # :nodoc:
      serializers.each { |s| s.delete(scope, user) }
    end

    # :api: private
    def find_serializer(name) # :nodoc:
      serializers.find { |s| s.class == ::Warden::Serializers[name] }
    end
  end # Proxy
end # Warden
