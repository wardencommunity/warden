# encoding: utf-8
module Warden
  # Sets up a place for deprecation of methods from the main proxy
  module ProxyDeprecation
    def default_strategies=(*strategies)
      warn "[DEPRECATION] warden.default_strategies= is deprecated. Instead use warden.default_strategies(*strategies) with an optional :scope => :scope)"
      strategies.push(:scope => @config.default_scope)
      default_strategies(*strategies)
    end
  end
end
