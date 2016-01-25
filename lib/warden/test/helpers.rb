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
          env = env_with_params
          setup_rack(success_app).call(env)
          env['warden']
        end
      end

      private

      FAILURE_APP = lambda{|e|[401, {"Content-Type" => "text/plain"}, ["You Fail!"]] }

      def env_with_params(path = "/", params = {}, env = {})
        method = params.delete(:method) || "GET"
        env = { 'HTTP_VERSION' => '1.1', 'REQUEST_METHOD' => "#{method}" }.merge(env)
        Rack::MockRequest.env_for("#{path}?#{Rack::Utils.build_query(params)}", env)
      end

      def setup_rack(app = nil, opts = {}, &block)
        app ||= block if block_given?

        opts[:failure_app]         ||= failure_app
        opts[:default_strategies]  ||= [:password]
        opts[:default_serializers] ||= [:session]
        blk = opts[:configurator] || proc{}

        Rack::Builder.new do
          use opts[:session] || Warden::Test::Helpers::Session unless opts[:nil_session]
          use Warden::Manager, opts, &blk
          run app
        end
      end

      def failure_app
        Warden::Test::Helpers::FAILURE_APP
      end

      def success_app
        lambda{|e| [200, {"Content-Type" => "text/plain"}, ["You Win"]]}
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
