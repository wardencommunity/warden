module Rack
  module Auth
    module Mixins
      module Common
        
        # Convinience method to access the session
        # :api: public
        def session
          @env['rack.session']
        end # session
        
        # Convenience method to access the rack request
        # :api: public
        def request
          @request ||= Rack::Request.new(@env)
        end # request
        
        # Convenience method to access the rack request params
        # :api: public
        def params
          request.params
        end # params
        
      end # Common
    end # Mixins
  end # Auth
end # Rack