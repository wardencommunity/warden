module Rack
  module Auth
    module Strategies
      class << self
        def add(label, strategy = nil, &blk)
          strategy = strategy.nil? ? Class.new(Rack::Auth::Strategies::Base, &blk) : strategy
          raise NoMethodError, "authenitate! is not declared in the #{label} strategy" if !strategy.instance_methods.include?("authenticate!")
          raise "#{label.inspect} is Not a Rack::Auth::Strategy::Base" if !strategy.ancestors.include?(Rack::Auth::Strategies::Base)
          _strategies[label] = strategy
        end
        
        def [](label)
          _strategies[label]
        end
        
        def clear!
          @strategies = {}
        end

        # :api: private
        def _strategies
          @strategies ||= {}
        end
      end # << self
      
    end # Strategies
  end # Auth
end # Rack
