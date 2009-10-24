module Warden::Spec
  module Helpers
    
    FAILURE_APP = lambda{|e|[401, {"Content-Type" => "text/plain"}, ["You Fail!"]] }
    
    def env_with_params(path = "/", params = {})
      method = params.fetch(:method, "GET")
      Rack::MockRequest.env_for(path, :input => Rack::Utils.build_query(params),
                                     'HTTP_VERSION' => '1.1',
                                     'REQUEST_METHOD' => "#{method}")
    end
    
    def setup_rack(app = nil, opts = {}, &block)
      app ||= block if block_given?
      opts[:default_strategies] ||= [:password]
      opts[:failure_app] ||= Warden::Spec::Helpers::FAILURE_APP
      Rack::Builder.new do 
        use Warden::Spec::Helpers::Session
        use Warden::Manager, opts do |manager|
          manager.failure_app = Warden::Spec::Helpers::FAILURE_APP
          manager.default_strategies *opts[:default_strategies]
        end
        run app
      end
    end
    
    def valid_response
      [200,{'Content-Type' => 'text/plain'},'OK']
    end
    
    def failure_app
      Warden::Spec::Helpers::FAILURE_APP
    end
    
    def success_app
      lambda{|e| [200, {"Content-Type" => "text/plain"}, ["You Win"]]}
    end
    
    class Session
      attr_accessor :app
      def initialize(app,configs = {})
        @app = app
      end
      
      def call(e)
        e['rack.session'] ||= {}      
        @app.call(e)
      end
    end # session
  end
end
