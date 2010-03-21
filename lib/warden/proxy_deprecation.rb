# encoding: utf-8
module Warden
  # Sets up a place for deprecation of methods from the main proxy
  module ProxyDeprecation
    def default_strategies=(*strategies)
      warn "[DEPRECATION] warden.default_strateiges= is deprecated.  Instead use warden.set_default_strategies(*strategies) with an optional :scope => :scope)"
      strategies.push(:scope => @config.default_scope)
      set_default_strategies(*strategies)
    end
  end
end
