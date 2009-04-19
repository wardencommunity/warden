module Rack
  module Auth
    # The middleware for Rack Authentication
    # The middlware requires that there is a session upstream
    # The middleware injects an authentication object into 
    # the rack environment hash
    class Manager
      attr_accessor :config, :failure_app
      
      # initialize the middleware.
      # Provide a :failure_app in the options to setup an application to run when there is a failure
      # :api: public 
      def initialize(app, config = {})
        @app = app
        @config = config
        yield self if block_given?
        
        # should ensure there is a failure application defined.
        @failure_app = config[:failure_app] if config[:failure_app]
        raise "No Failure App provided" unless @failure_app
        self
      end 
      
      # :api: private
      def call(env) # :nodoc:
        # if this is downstream from another rack-auth instance, don't do anything.
        return @app.call(env) unless env['rack-auth'].nil? 
        
        env['rack-auth'] = Proxy.new(env, @config)
        result = catch(:auth) do
          @app.call(env)
        end

        result ||= {}
        case result
        when Array
          if result.first != 401
            return result
          else
            call_failure_app(env)
          end
        when Hash
          if (result[:action] ||= :unauthenticated) == :unauthenticated
            process_unauthenticated(result,env)
          end # case result
        end
      end
      
      class << self
        # Does the work of storing the user in the session
        # :api: private
        def _store_user(user, session, scope = :default) # :nodoc: 
          session["rack-auth.user.#{scope}.key"] = user_session_key.call(user)
        end
        
        # Does the work of fetching the user from the session
        # :api: private
        def _fetch_user(session, scope = :default) # :nodoc:
          user_from_session.call(session["rack-auth.user.#{scope}.key"])
        end
        
        # Prepares the user to serialize into the session.
        # Any object that can be serialized into the session in some way can be used as a "user" object
        # Generally however complex object should not be stored in the session.  
        # If possible store only a "key" of the user object that will allow you to reconstitute it.
        #
        # Example:
        #   Rack::Auth::Manager.user_session_key{ |user| user.id }
        #
        # :api: public
        def user_session_key(&block)
          @user_session_key = block if block_given?
          @user_session_key ||= lambda{|user| user}
        end
        
        # Reconstitues the user from the session.
        # Use the results of user_session_key to reconstitue the user from the session on requests after the initial login
        # 
        # Example:
        #   Rack::Auth::Manager.user_from_session{ |id| User.get(id) }
        #
        # :api: public
        def user_from_session(&blk)
          @user_from_session = blk if block_given?
          @user_from_session ||= lambda{|key| key}
        end                      
      end
      
      private
      # When a request is unauthentiated, here's where the processing occurs.  
      # It looks at the result of the proxy to see if it's been executed and what action to take.
      # :api: private
      def process_unauthenticated(result, env)
        case env['rack-auth'].result
        when :failure
          call_failure_app(env, result)
        when :redirect
          [env['rack-auth']._status, env['rack-auth'].headers, [env['rack-auth'].message || "You are being redirected to #{env['rack-auth'].headers['Location']}"]]
        when :custom
          env['rack-auth'].custom_response
        when nil
          call_failure_app(env, result)
        end # case env['rack-auth'].result
      end
      
      # Calls the failure app.
      # The before_failure hooks are run on each failure
      # :api: private
      def call_failure_app(env, opts = {})
        env["PATH_INFO"] = "/#{opts[:action]}"
        
        # Call the before failure callbacks
        Rack::Auth::Manager._before_failure.each{|hook| hook.call(env,opts)}
        
        @failure_app.call(env)
      end # call_failure_app
    end
  end
end
