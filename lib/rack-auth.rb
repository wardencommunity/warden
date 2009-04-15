require 'forwardable'
$:.unshift File.join(File.dirname(__FILE__))
require 'rack-auth/mixins/common'
require 'rack-auth/proxy'
require 'rack-auth/manager'
require 'rack-auth/errors'
require 'rack-auth/authentication/hooks'
require 'rack-auth/authentication/strategy_base'
require 'rack-auth/authentication/strategies'


module Rack
  module Auth
  end
end
