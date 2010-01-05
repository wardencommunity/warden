# encoding: utf-8
require 'warden/hooks'
require 'warden/config'
require 'warden/manager_deprecation'

module Warden
  # The middleware for Rack Authentication
  # The middlware requires that there is a session upstream
  # The middleware injects an authentication object into
  # the rack environment hash
  class Manager
    extend Warden::Hooks
    extend Warden::ManagerDeprecation

    attr_accessor :config

    # Initialize the middleware. If a block is given, a Warden::Config is yielded so you can properly
    # configure the Warden::Manager.
    # :api: public
    def initialize(app, options={})
      @app, @config = app, Warden::Config.new(options)
      yield @config if block_given?
      self
    end

    # Invoke the application guarding for throw :warden.
    # If this is downstream from another warden instance, don't do anything.
    # :api: private
    def call(env) # :nodoc:
      return @app.call(env) unless env['warden'].nil?

      env['warden'] = Proxy.new(env, self)
      result = catch(:warden) do
        @app.call(env)
      end

      result ||= {}
      case result
      when Array
        if result.first != 401
          return result
        else
          process_unauthenticated({:original_response => result, :action => :unauthenticated}, env)
        end
      when Hash
        result[:action] ||= :unauthenticated
        process_unauthenticated(result, env)
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
      elsif config.failure_app
        env["PATH_INFO"] = "/#{opts[:action]}"
        env["warden.options"] = opts

        Warden::Manager._before_failure.each { |hook| hook.call(env, opts) }
        config.failure_app.call(env).to_a
      else
        raise "No Failure App provided"
      end
    end # call_failure_app
  end
end # Warden
