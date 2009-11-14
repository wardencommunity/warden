# encoding: utf-8
module Warden
  module Declarable
      
    def add(label, declaration = nil, &block)
      base = self.const_get(:Base)

      declaration ||= Class.new(base)
      declaration.class_eval(&block) if block_given?

      check_validity!(label, declaration)
      raise "#{label.inspect} is not a #{base}" unless declaration.ancestors.include?(base)

      _declarations[label] = declaration
    end

    # Provides access to declarations by label
    # :api: public
    def [](label)
      _declarations[label]
    end

    # Clears all declared.
    # :api: public
    def clear!
      _declarations.clear
    end

    # :api: private
    def _declarations
      @declarations ||= {}
    end
    
  end # Declarable
end # Warden
