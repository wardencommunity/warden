require File.dirname(__FILE__) + '/../spec_helper'

describe Rack::Auth::Proxy do
  
  before(:all) do
    Dir[File.join(File.dirname(__FILE__), "strategies/**/*.rb")].each{|f| load f}
  end

  before(:each) do
    @basic_app = lambda{|env| [200,{'Content-Type' => 'text/plain'},'OK']}
    @authd_app = lambda do |e| 
      if e['rack.auth'].authenticated?
        [200,{'Content-Type' => 'text/plain'},"OK"]
      else
        [401,{'Content-Type' => 'text/plain'},"You Fail"]
      end
    end
    @env = Rack::MockRequest.
      env_for('/', 'HTTP_VERSION' => '1.1', 'REQUEST_METHOD' => 'GET')
  end # before(:each)
  
  describe "authentication" do

    it "should not check the authentication if it is not checked" do
      app = setup_rack(@basic_app)
      app.call(@env).first.should == 200
    end

    it "should check the authentication if it is explicity checked" do
      app = setup_rack(@authd_app)
      app.call(@env).first.should == 401
    end

    it "should not allow the request if incorrect conditions are supplied" do
      env = env_with_params("/", :foo => "bar")
      app = setup_rack(@authd_app)
      response = app.call(env)
      response.first.should == 401
    end

    it "should allow the request if the correct conditions are supplied" do
      env = env_with_params("/", :username => "fred", :password => "sekrit")
      app = setup_rack(@authd_app)
      resp = app.call(env)
      resp.first.should == 200
    end
    
    describe "authenticate!" do
      
      it "should allow authentication in my application" do
        env = env_with_params('/', :username => "fred", :password => "sekrit")
        app = lambda do |env|
          env['rack.auth'].should be_authenticated
          env['rack.auth.spec.strategies'].should == [:password]
        end
      end
      
      it "should be false in my application" do
        env = env_with_params("/", :foo => "bar")
        app = lambda do |env|
          env['rack.auth'].should_not be_authenticated
          env['rack.auth.spec.strategies'].should == [:password]
          valid_response
        end
        setup_rack(app).call(env)
      end
      
      it "should allow me to select which strategies I use in my appliction" do
        env = env_with_params("/", :foo => "bar")
        app = lambda do |env|
          env['rack.auth'].should_not be_authenticated(:failz)
          env['rack.auth.spec.strategies'].should == [:failz]
          valid_response
        end
        setup_rack(app).call(env)
      end
      
      it "should allow me to get access to the user at auth.user" do
        env = env_with_params("/")
        app = lambda do |env|
          env['rack.auth'].should be_authenticated(:pass)
          env['rack.auth.spec.strategies'].should == [:pass]
          valid_response
        end
        setup_rack(app).call(env)
      end
      
      it "should try multiple authentication strategies" do
        env = env_with_params("/")
        app = lambda do |env|
          env['rack.auth'].should be_authenticated(:password, :pass)
          env['rack.auth.spec.strategies'].should == [:password, :pass]
          valid_response
        end
        setup_rack(app).call(env)
      end
    end
  end # describe "authentication"
  
  describe "set user" do
    it "should store the user into the session" do
      env = env_with_params("/")
      app = lambda do |env|
        env['rack.auth'].should be_authenticated(:pass)
        env['rack.auth'].user.should == "Valid User"
        env['rack.session']["user.default"].should == "Valid User"
        valid_response
      end
      setup_rack(app).call(env)
    end
    
    
  end
end
