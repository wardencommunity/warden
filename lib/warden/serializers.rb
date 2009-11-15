# encoding: utf-8
require 'warden/declarable'

module Warden
  module Serializers
    extend Warden::Declarable
    
    class << self
      def check_validity!(label, serializer)
        [:fetch, :store, :stored?, :delete].each do |method|
          next if serializer.method_defined?(method)
          raise NoMethodError, "#{method} is not declared in the #{label.inspect} serializer"
        end
      end
      
      alias :_serializers :_declarations
    end # << self

  end # Serializers
end # Warden
