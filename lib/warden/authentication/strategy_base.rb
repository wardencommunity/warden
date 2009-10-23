# encoding: utf-8
module Warden
  module Strategies
    class Base
      # :api: public
      attr_accessor :user, :message

      #:api: private
      attr_accessor :result, :custom_response

      # Setup for redirection
      # :api: private
      attr_reader   :_status

      # Accessor for the rack env
      # :api: public
      attr_reader   :env, :scope
      include ::Warden::Mixins::Common

      # :api: private
      def initialize(env, scope=nil, config={}) # :nodoc:
        @scope, @config = scope, config
        @env, @_status, @headers = env, nil, {}
        @halted = false
      end

      # The method that is called from above.  This method calls the underlying authenticate! method
      # :api: private
      def _run! # :nodoc:
        result = authenticate!
        self
      end

      # Acts as a guarding method for the strategy.
      # If #valid? responds false, the strategy will not be executed
      # Overwrite with your own logic
      # :api: overwritable
      def valid?; true; end

      # Provides access to the headers hash for setting custom headers
      # :api: public
      def headers(header = {})
        @headers ||= {}
        @headers.merge! header
        @headers
      end

      # Access to the errors object.
      # :api: public
      def errors
        @env['warden.errors']
      end

      # Cause the processing of the strategies to stop and cascade no further
      # :api: public
      def halt!
        @halted = true
      end

      # Checks to see if a strategy was halted
      # :api: public
      def halted?
        !!@halted
      end

      # A simple method to return from authenticate! if you want to ignore this strategy
      # :api: public
      def pass; end

      # Whenever you want to provide a user object as "authenticated" use the +success!+ method.
      # This will halt the strategy, and set the user in the approprieate scope.
      # It is the "login" method
      #
      # Parameters:
      #   user - The user object to login.  This object can be anything you have setup to serialize in and out of the session
      #
      # :api: public
      def success!(user)
        halt!
        @user   = user
        @result = :success
      end

      # This causes the strategy to fail.  It does not throw an :warden symbol to drop the request out to the failure application
      # You must throw an :warden symbol somewhere in the application to enforce this
      # :api: public
      def fail!(message = "Failed to Login")
        halt!
        @message = message
        @result = :failure
      end

      # Causes the authentication to redirect.  An :warden symbol must be thrown to actually execute this redirect
      #
      # Parameters:
      #  url <String> - The string representing the URL to be redirected to
      #  pararms <Hash> - Any parameters to encode into the URL
      #  opts <Hash> - Any options to recirect with.
      #    available options: permanent => (true || false)
      #
      # :api: public
      def redirect!(url, params = {}, opts = {})
        halt!
        @_status = opts[:permanent] ? 301 : 302
        headers["Location"] = url
        headers["Location"] << "?" << Rack::Utils.build_query(params) unless params.empty?
        headers["Content-Type"] = opts[:content_type] || 'text/plain'

        @message = opts[:message].nil? ? "You are being redirected to #{headers["Location"]}" : opts[:message]

        @result = :redirect

        headers["Location"]
      end

      # Return a custom rack array.  You must throw an :warden symbol to activate this
      # :api: public
      def custom!(response)
        halt!
        @custom_response = response
        @result = :custom
      end

    end # Base
  end # Strategies
end # Warden
