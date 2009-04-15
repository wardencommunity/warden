module Rack::Auth::Spec
  module Helpers
    def env_with_params(path = "/", params = {})
      method = params.fetch(:method, "GET")
      Rack::MockRequest.env_for(path, :input => Rack::Utils.build_query(params),
                                     'HTTP_VERSION' => '1.1',
                                     'REQUEST_METHOD' => "#{method}")
    end
    
    def setup_rack(app = nil, opts = {}, &block)
      app ||= block if block_given?
      opts[:default] ||= [:password]
      opts[:failure_app] ||= failure_app
      Rack::Builder.new do 
        use Rack::Session::Cookie
        use Rack::Auth::Manager, opts
        run app
      end
    end
    
    def valid_response
      [200,{'Content-Type' => 'text/plain'},'OK']
    end
    
    def failure_app
      lambda{|e|[401, {"Content-Type" => "text/plain"}, ["You Fail!"]] }
    end
    
    def success_app
      lambda{|e| [200, {"Content-Type" => "text/plain"}, ["You Win"]]}
    end
  end
end