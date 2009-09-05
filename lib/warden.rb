# encoding: utf-8
require 'forwardable'
$:.unshift File.join(File.dirname(__FILE__))
require 'warden/mixins/common'
require 'warden/proxy'
require 'warden/manager'
require 'warden/errors'
require 'warden/authentication/hooks'
require 'warden/authentication/strategy_base'
require 'warden/authentication/strategies'


module Warden
  class NotAuthenticated < StandardError; end
end
