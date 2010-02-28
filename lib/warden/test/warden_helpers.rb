# encoding: utf-8

module Warden
  # Provides helper methods to warden for testing.
  #
  # To setup warden in test mode call the +test_mode!+ method on warden
  #
  # @example
  #   Warden.test_mode!
  #
  # This will provide a number of methods.
  # Warden.on_next_request(&blk) - captures a block which is yielded the warden proxy on the next request
  # Warden.test_reset! - removes any captured blocks that would have been executed on the next request
  #
  # Warden.test_reset! should be called in after blocks for rspec, or teardown methods for Test::Unit
  def self.test_mode!
    unless Warden::Test::WardenHelpers === Warden
      Warden.extend Warden::Test::WardenHelpers
      Warden::Manager.on_request do |proxy|
        while blk = Warden._on_next_request.shift
          blk.call(proxy)
        end
      end
    end
    true
  end

  module Test
    module WardenHelpers
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
      end

      # A containter for the on_next_request items.
      # @api private
      def _on_next_request
        @_on_next_request ||= []
        @_on_next_request
      end
    end
  end
end
