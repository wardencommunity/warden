module Rack
  module Auth
    module Strategies
      class Base
        attr_accessor :user, :message, :result, :custom_response
        attr_reader   :_status, :env
        include ::Rack::Auth::Mixins::Common
        
        def initialize(env, config = {})
          @config = config
          @env, @_status, @headers = env, nil, {}
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
      
        def errors
          @env['auth.errors']
        end
        
        def halt!
          @halted = true
        end
        
        def halted?
          !!@halted
        end
        
        def pass; end
        
        def success!(user)
          halt!
          @user   = user
          @result = :success
        end
        
        def fail!(message = "Failed to Login")
          halt!
          @message = message
          @result = :failure
        end
        
        def redirect!(url, params = {}, opts = {})
          halt!
          @_status = opts[:permanent] ? 301 : 302
          headers["Location"] = url
          headers["Location"] << "?" << Rack::Utils.build_query(params) unless params.empty?
            
          @message = opts[:message].nil? ? "You are being redirected to #{headers["Location"]}" : opts[:message]
          
          @result = :redirect

          headers["Location"]
        end
        
        def custom!(response)
          halt!
          @custom_response = response
          @result = :custom
        end  
        
      end # Base
    end # Strategies
  end # Auth
end # Rack