# encoding: utf-8
module Warden
  module Strategies
    class << self
      
      # Adds a strategy to the grab-bag of strategies available to use.
      # A strategy is a place where you can put logic related to authentication.
      # A strategy inherits from Warden::Strategies::Base.  The _add_ method provides a clean way
      # to declare your strategies.  
      # You _must_ declare an @authenticate!@ method.
      # You _may_ provide a @valid?@ method.
      # The valid method should return true or false depending on if the strategy is a valid one for the request.
      # 
      # Parameters: 
      #   <label: Symbol> The label is the name given to a strategy.  Use the label to refer to the strategy when authenticating
      #   <strategy: Class|nil> The optional stragtegy argument if set _must_ be a class that inherits from Warden::Strategies::Base and _must_
      #                         implement an @authenticate!@ method
      #   <block> The block acts as a convinient way to declare your strategy.  Inside is the class definition of a strategy.
      #
      # Examples:
      #
      #   Block Declared Strategy:
      #    Warden::Strategies.add(:foo) do
      #      def authenticate!
      #        # authentication logic
      #      end
      #    end
      #
      #    Class Declared Strategy:
      #      Warden::Strategies.add(:foo, MyStrategy)
      #
      # :api: public
      def add(label, strategy = nil, &blk)
        strategy = strategy.nil? ? Class.new(Warden::Strategies::Base, &blk) : strategy
        raise NoMethodError, "authenticate! is not declared in the #{label} strategy" if !strategy.method_defined?(:authenticate!)
        raise "#{label.inspect} is Not a Warden::Strategy::Base" if !strategy.ancestors.include?(Warden::Strategies::Base)
        _strategies[label] = strategy
      end
      
      # Provides access to declared strategies by label
      # :api: public
      def [](label)
        _strategies[label]
      end
      
      # Clears all declared middleware.
      # :api: public
      def clear!
        @strategies = {}
      end

      # :api: private
      def _strategies
        @strategies ||= {}
      end
    end # << self
    
  end # Strategies
end # Warden
