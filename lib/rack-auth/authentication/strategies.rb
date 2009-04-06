module Rack
  module Auth
    module Strategies
      class << self
        def add(label, strategy = nil, &blk)
          strategy = if strategy.nil? 
            t = Class.new(Rack::Auth::Strategies::Base, &blk)
            # Need to check that the strategy implements and authenticate! method
            raise NoMethodError, "authenticate! is not declared in the #{label} strategy" if !t.instance_methods.include?("authenticate!")
            t
          else
            if Class === strategy && block_given?
              Class.new(strategy, &blk)
            elsif [:_run!, :user, :status, :headers].all?{ |m| strategy.instance_methods.include?(m.to_s) }
              strategy
            else
              raise "This is not a valid strategy"
            end
          end
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
