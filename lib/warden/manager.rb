# encoding: utf-8
module Warden
  # The middleware for Rack Authentication
  # The middlware requires that there is a session upstream
  # The middleware injects an authentication object into
  # the rack environment hash
  class Manager
    attr_accessor :config, :failure_app

    # initialize the middleware.
    # Provide a :failure_app in the options to setup an application to run when there is a failure
    # The manager is yielded when initialized with a block.  This is useful when declaring it in Rack::Builder
    # :api: public
    def initialize(app, config = {})
      @app = app
      @config = config
      yield self if block_given?

      # Should ensure there is a failure application defined.
      @failure_app = config[:failure_app] if config[:failure_app]
      raise "No Failure App provided" unless @failure_app
      self
    end

    # Do not raise an error if a missing strategy is given by default.
    # :api: plugin
    def silence_missing_strategies!
      @config[:silence_missing_strategies] = true
    end

    # Set the default strategies to use.
    # :api: public
    def default_strategies(*strategies)
      if strategies.empty?
        @config[:default_strategies]
      else
        @config[:default_strategies] = strategies.flatten
      end
    end

    # :api: private
    def call(env) # :nodoc:
      # if this is downstream from another warden instance, don't do anything.
      return @app.call(env) unless env['warden'].nil?

      env['warden'] = Proxy.new(env, @config)
      result = catch(:warden) do
        @app.call(env)
      end

      result ||= {}
      case result
      when Array
        if result.first != 401
          return result
        else
          call_failure_app(env, :original_response => result)
        end
      when Hash
        result[:action] ||= :unauthenticated
        process_unauthenticated(result, env)
      end
    end

    class << self

      # Does the work of storing the user in the session
      # :api: private
      def _store_user(user, session, scope = :default) # :nodoc:
        return nil unless user
        session["warden.user.#{scope}.key"] = serialize_into_session.call(user)
      end

      # Does the work of fetching the user from the session
      # :api: private
      def _fetch_user(session, scope = :default) # :nodoc:
        key = session["warden.user.#{scope}.key"]
        return nil unless key
        serialize_from_session.call(key)
      end

      # Prepares the user to serialize into the session.
      # Any object that can be serialized into the session in some way can be used as a "user" object
      # Generally however complex object should not be stored in the session.
      # If possible store only a "key" of the user object that will allow you to reconstitute it.
      #
      # Example:
      #   Warden::Manager.serialize_into_session{ |user| user.id }
      #
      # :api: public
      def serialize_into_session(&block)
        @serialize_into_session = block if block_given?
        @serialize_into_session ||= lambda{|user| user}
      end

      # Reconstitues the user from the session.
      # Use the results of user_session_key to reconstitue the user from the session on requests after the initial login
      #
      # Example:
      #   Warden::Manager.serialize_from_session{ |id| User.get(id) }
      #
      # :api: public
      def serialize_from_session(&blk)
        @serialize_from_session = blk if block_given?
        @serialize_from_session ||= lambda{|key| key}
      end
    end

    private
    # When a request is unauthentiated, here's where the processing occurs.
    # It looks at the result of the proxy to see if it's been executed and what action to take.
    # :api: private
    def process_unauthenticated(result, env)
      action = result[:result] || env['warden'].result

      case action
        when :redirect
          [env['warden']._status, env['warden'].headers, [env['warden'].message || "You are being redirected to #{env['warden'].headers['Location']}"]]
        when :custom
          env['warden'].custom_response
        else
          call_failure_app(env, result)
      end
    end

    # Calls the failure app.
    # The before_failure hooks are run on each failure
    # :api: private
    def call_failure_app(env, opts = {})
      if env['warden'].custom_failure?
        opts[:original_response]
      else
        env["PATH_INFO"] = "/#{opts[:action]}"
        env["warden.options"] = opts

        # Call the before failure callbacks
        Warden::Manager._before_failure.each{|hook| hook.call(env,opts)}

        @failure_app.call(env).to_a
      end
    end # call_failure_app
  end
end # Warden
