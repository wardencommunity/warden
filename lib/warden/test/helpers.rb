# encoding: utf-8

require 'rack'

module Warden
  module Test
    # A collection of test helpers for testing full stack rack applications using Warden
    # These provide the ability to login and logout on any given request
    # Note: During the teardown phase of your specs you should include: Warden.test_reset!
    module Helpers
      def self.included(base)
        ::Warden.test_mode!
      end

      # A helper method that will perform a login of a user in warden for the next request.
      # Provide it the same options as you would to Warden::Proxy#set_user
      # @see Warden::Proxy#set_user
      # @api public
      def login_as(user, opts = {})
        Warden.on_next_request do |proxy|
          opts[:event] ||= :authentication
          proxy.set_user(user, opts)
        end
      end

      # Logs out a user from the session.
      # Without arguments, all users will be logged out
      # Provide a list of scopes to only log out users with that scope.
      # @see Warden::Proxy#logout
      # @api public
      def logout(*scopes)
        Warden.on_next_request do |proxy|
          proxy.logout(*scopes)
        end
      end

      # A helper method that provides the warden object by mocking the env variable.
      # @api public
      def warden
        @warden ||= begin
          env['warden']
        end
      end

      private

      def env
        @env ||= begin
          request = Rack::MockRequest.env_for(
            "/?#{Rack::Utils.build_query({})}",
            { 'HTTP_VERSION' => '1.1', 'REQUEST_METHOD' => 'GET' }
          )
          app.call(request)

          request
        end
      end

      def app
        @app ||= begin
          opts = {
            failure_app: lambda {
              [401, { 'Content-Type' => 'text/plain' }, ['You Fail!']]
            },
            default_strategies: :password,
            default_serializers: :session
          }
          Rack::Builder.new do
            use Warden::Test::Helpers::Session
            use Warden::Manager, opts, &proc {}
            run lambda { |e|
              [200, { 'Content-Type' => 'text/plain' }, ['You Win']]
            }
          end
        end
      end

      class Session
        attr_accessor :app
        def initialize(app,configs = {})
          @app = app
        end

        def call(e)
          e['rack.session'] ||= {}
          @app.call(e)
        end
      end # session
    end
  end
end
