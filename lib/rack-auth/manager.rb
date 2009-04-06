module Rack
  module Auth
    # The middleware for Rack Authentication
    # The middlware requires that there is a session upstream
    # The middleware injects an authentication object into 
    # the rack environment hash
    class Manager
      attr_accessor :config
      
      def initialize(app, config = {})
        @app = app
        @failure_app = config[:failure_app]
        raise "You must specify a :failure_app for authentication" unless @failure_app
        @config = config
      end
      
      def call(env)
        env['rack.auth'] = Proxy.new(env, @config)
        result = catch(:unauthenticated) do
          @app.call(env)
        end
        
        if Array === result
          if result.first != 401
            result
          else
            @failure_app.call(env)
          end
        else # The unauthenticated symbol was thrown
          t = env['rack.auth'].rack_response
          if t.first == 401 # If nothing is found
            @failure_app.call(env)
          else
            t
          end
        end
      end
      
      class << self
        def store_user(user, scope, session)
          session["user.#{scope}"] = user_session_key(user)
        end
        
        def user_session_key(user)
          user
        end
      end
      
      private 
      def failure_response(env)
        auth = env['rack.auth']
        [401, auth.headers, [auth.message]]
      end
      
      def redirect_response(env)
        auth = env['rack.auth']
      end

    end
  end
end
