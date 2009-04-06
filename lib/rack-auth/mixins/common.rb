module Rack
  module Auth
    module Mixins
      module Common
        
        def session
          @session = begin
             if @env['rack.session']
               @env['rack.session']
             else
               raise "No Session Found"
             end
           end
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