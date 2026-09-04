# encoding: utf-8
# frozen_string_literal: true

module Warden

  module Test
    module WardenHelpers
      # Detects requests that a browser sends in the background (fetch/XHR data
      # calls), as opposed to page loads. Only a browser attaches Sec-Fetch-Mode,
      # and JavaScript cannot forge or remove it, so requests made directly by a
      # test client (e.g. rack-test) never match and keep the default behaviour.
      # Among browser requests, an Accept header without text/html separates
      # background data calls from page loads: both a classic navigation and a
      # Turbo/Hotwire fetch ask for html, a data call does not.
      # @see Warden::Test::WardenHelpers#skip_background_requests=
      # @api public
      BROWSER_BACKGROUND_REQUEST = lambda do |env|
        !env['HTTP_SEC_FETCH_MODE'].to_s.empty? && !env['HTTP_ACCEPT'].to_s.include?('text/html')
      end

      # Returns list of regex objects that match paths expected to be an asset
      # @see Warden::Proxy#asset_request?
      # @api public
      def asset_paths
        @asset_paths ||= [/^\/assets\//]
      end

      # Sets list of regex objects that match paths expected to be an asset
      # @see Warden::Proxy#asset_request?
      # @api public
      def asset_paths=(*vals)
        @asset_paths = vals
      end

      # Adds a block to be executed on the next request when the stack reaches warden.
      # The warden proxy is yielded to the block
      # @api public
      def on_next_request(&blk)
        _on_next_request << blk
      end

      # Tells test mode to keep on_next_request blocks queued while browser
      # background requests (fetch/XHR data calls) go through, so that only a
      # page load consumes them. Without this, a background request still in
      # flight when the test logs in can consume the queued login: the session
      # cookie travels in that response, and if the browser cancels the request
      # while navigating away, the cookie is discarded with it and the next page
      # is served unauthenticated.
      #
      # Accepts +true+ to enable the default detection (BROWSER_BACKGROUND_REQUEST),
      # a callable that receives the rack env to customize it, or +false+ / +nil+
      # to disable it (the default, preserving the previous behaviour).
      #
      # @example
      #   Warden.skip_background_requests = true
      #   Warden.skip_background_requests = ->(env) { env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest' }
      # @api public
      attr_accessor :skip_background_requests

      # Whether the request should not consume the on_next_request blocks,
      # according to the skip_background_requests setting.
      # @api private
      def _skip_background_request?(env)
        return false if !skip_background_requests

        detector = skip_background_requests == true ? BROWSER_BACKGROUND_REQUEST : skip_background_requests
        detector.call(env)
      end

      # resets wardens tests
      # any blocks queued to execute will be removed
      # @api public
      def test_reset!
        _on_next_request.clear
      end

      # A container for the on_next_request items.
      # @api private
      def _on_next_request
        @_on_next_request ||= []
        @_on_next_request
      end
    end
  end
end
