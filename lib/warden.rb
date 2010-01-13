# encoding: utf-8
require 'forwardable'

require 'warden/mixins/common'
require 'warden/proxy'
require 'warden/manager'
require 'warden/errors'
require 'warden/session_serializer'
require 'warden/strategies'
require 'warden/strategies/base'

module Warden
  class NotAuthenticated < StandardError; end
end
