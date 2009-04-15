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
        env['auth'] = Proxy.new(env, @config)
        result = catch(:auth) do
          @app.call(env)
        end
        
        case result
        when Array
          if result.first != 401
            return result
          else
            call_failure_app(env)
          end
        when Hash
          if (result[:action] ||= :unauthenticated) == :unauthenticated
            case env['auth'].result
            when :failure
              call_failure_app(env, result)
            when :redirect
              [env['auth']._status, env['auth'].headers, env['auth'].message || "You are being redirected to #{env['auth'].headers['Location']}"]
            when :custom
              env['auth'].custom_response
            when nil
              call_failure_app(env, result)
            end # case env['auth'].result
          end # case result
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
        auth = env['auth']
        [401, auth.headers, [auth.message]]
      end
      
      def redirect_response(env)
        auth = env['auth']
      end
      
      def call_failure_app(env, opts = {})
        env["PATH_INFO"] = "/#{opts[:action]}"
        @failure_app.call(env)
      end # call_failure_app
    end
  end
end
