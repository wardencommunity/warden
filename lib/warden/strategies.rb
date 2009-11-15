# encoding: utf-8
require 'warden/declarable'

module Warden
  module Strategies
    extend Warden::Declarable
    
    class << self
      def check_validity!(label, strategy)
        return if strategy.method_defined?(:authenticate!)
        raise NoMethodError, "authenticate! is not declared in the #{label.inspect} strategy" 
      end
      
      alias :_strategies :_declarations
    end # << self

  end # Strategies
end # Warden
