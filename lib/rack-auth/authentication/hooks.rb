module Rack
  module Auth
    class Manager
      
      class << self
        
        def after_set_user(&block)
          raise BlockNotGiven unless block_given?
          _after_set_user << block
        end
        
        def _after_set_user
          @_after_set_user ||= []
        end
        
        def after_authentication(&block)
          raise BlockNotGiven unless block_given?
          _after_authentication << block
        end
        
        def _after_authentication
          @_after_authentication ||= []
        end
        
        def before_failure(&block)
          _before_failure << block
        end
        
        def _before_failure
          @_before_failure ||= []
        end
      end
      
    end # Manager
  end # Auth
end # Rack