module Rack
  module Auth
    module Strategies
      class Base
        attr_accessor :user, :message
        attr_writer   :status
        include ::Rack::Auth::Mixins::Common
        
        def initialize(env, config = {})
          @config = config
          @env, @status, @headers = env, nil, {}
          @halted = false       
        end
        
        def _run!
          result = authenticate!
          self
        end
        
        def headers(header = {})
          @headers ||= {}
          @headers.merge! header
          @headers
        end
        
        def status
          @status ||= 401
        end
        
        def errors
          @env['rack.auth.errors']
        end
        
        def halt!
          @halted = true
        end
        
        def halted?
          !!@halted
        end
        
        def pass; end
        
        def success!(user)
          @user   = user
          @status = 200
        end
        
        def fail!(message = "Failed to Login")
          @message = message
          @status = 401
          halt!
        end
        
        def redirect!(url, params = {}, opts = {})
          headers["Location"] = url
          headers["Location"] << "?" << Rack::Utils.build_query(params) unless params.empty?
          
          @status = 302
          
          @message = opts[:message].nil? ? "You are being redirected to #{headers["Location"]}" : opts[:message]
          
          halt!
          headers["Location"]
        end
        
        def custom!(response)
          halt!
          @status = response[0]
          
          headers.clear
          headers.merge! response[1]
          
          @message = response[2]
          response
        end
        
        def rack_response
          [@status, @headers, [@message]]
        end       
        
      end # Base
    end # Strategies
  end # Auth
end # Rack