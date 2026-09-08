# encoding: utf-8
# frozen_string_literal: true

module Warden

  module Test
    module WardenHelpers
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

      # resets wardens tests
      # any blocks queued to execute will be removed
      # @api public
      def test_reset!
        _on_next_request.clear
        _test_users.clear
      end

      # A container for the on_next_request items.
      # @api private
      def _on_next_request
        @_on_next_request ||= []
        @_on_next_request
      end

      # A persistent store of test users keyed by scope.
      # Unlike _on_next_request, these survive across multiple requests,
      # preventing race conditions with background requests.
      # @api private
      def _test_users
        @_test_users ||= {}
      end
    end
  end
end
