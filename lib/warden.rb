# encoding: utf-8
require 'forwardable'
$:.unshift File.join(File.dirname(__FILE__))

require 'warden/mixins/common'
require 'warden/proxy'
require 'warden/manager'
require 'warden/errors'
require 'warden/strategies'
require 'warden/strategies/base'
require 'warden/serializers'
require 'warden/serializers/base'
require 'warden/serializers/cookie'
require 'warden/serializers/session'

module Warden
  class NotAuthenticated < StandardError; end
end
