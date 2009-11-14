# encoding: utf-8
require 'forwardable'
$:.unshift File.join(File.dirname(__FILE__))

require 'warden/mixins/common'
require 'warden/proxy'
require 'warden/manager'
require 'warden/errors'
require 'warden/authentication/hooks'
require 'warden/authentication/declarable'
require 'warden/authentication/strategies'
require 'warden/authentication/strategies/base'
require 'warden/authentication/serializers'
require 'warden/authentication/serializers/base'
require 'warden/authentication/serializers/cookie'
require 'warden/authentication/serializers/session'

module Warden
  class NotAuthenticated < StandardError; end
end
