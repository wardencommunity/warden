module Rack
  module Auth
    module Mixins
      module Common
        
        def session
          @env['rack.session']
        end # session
        
        def request
          @request ||= Rack::Request.new(@env)
        end # request

        def params
          request.params
        end # params
        
      end # Common
    end # Mixins
  end # Auth
end # Rack