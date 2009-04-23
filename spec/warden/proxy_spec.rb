require File.dirname(__FILE__) + '/../spec_helper'

describe Warden::Proxy do
  
  before(:all) do
    Dir[File.join(File.dirname(__FILE__), "strategies/**/*.rb")].each{|f| load f}
  end

  before(:each) do
    @basic_app = lambda{|env| [200,{'Content-Type' => 'text/plain'},'OK']}
    @authd_app = lambda do |e| 
      if e['warden'].authenticated?
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
          env['warden'].should be_authenticated
          env['warden.spec.strategies'].should == [:password]
        end
      end
      
      it "should be false in my application" do
        env = env_with_params("/", :foo => "bar")
        app = lambda do |env|
          env['warden'].should_not be_authenticated
          env['warden.spec.strategies'].should == [:password]
          valid_response
        end
        setup_rack(app).call(env)
      end
      
      it "should allow me to select which strategies I use in my appliction" do
        env = env_with_params("/", :foo => "bar")
        app = lambda do |env|
          env['warden'].should_not be_authenticated(:failz)
          env['warden.spec.strategies'].should == [:failz]
          valid_response
        end
        setup_rack(app).call(env)
      end
      
      it "should allow me to get access to the user at warden.user." do
        env = env_with_params("/")
        app = lambda do |env|
          env['warden'].should be_authenticated(:pass)
          env['warden.spec.strategies'].should == [:pass]
          valid_response
        end
        setup_rack(app).call(env)
      end
      
      it "should try multiple authentication strategies" do
        env = env_with_params("/")
        app = lambda do |env|
          env['warden'].should be_authenticated(:password, :pass)
          env['warden.spec.strategies'].should == [:password, :pass]
          valid_response
        end
        setup_rack(app).call(env)
      end
      
      it "should look for an active user in the session with authenticate!" do
        app = lambda do |env|
          env['rack.session']["warden.user.default.key"] = "foo as a user"
          env['warden'].authenticate!(:pass)
          valid_response
        end
        env = env_with_params
        setup_rack(app).call(env)
        env['warden'].user.should == "foo as a user"
      end
      
      it "should look for an active user in the session with authenticate?" do
        app = lambda do |env|
          env['rack.session']['warden.user.foo_scope.key'] = "a foo user"
          env['warden'].authenticated?(:pass, :scope => :foo_scope)
          valid_response
        end
        env = env_with_params
        setup_rack(app).call(env)
        env['warden'].user(:foo_scope).should == "a foo user"
      end
      
      it "should login 2 different users from the session" do
        app = lambda do |env|
          env['rack.session']['warden.user.foo.key'] = 'foo user'
          env['rack.session']['warden.user.bar.key'] = 'bar user'
          env['warden'].authenticated?(:pass, :scope => :foo).should be_true
          env['warden'].authenticated?(:pass, :scope => :bar).should be_true
          env['warden'].authenticated?(:password).should be_false
          valid_response
        end
        env = env_with_params
        setup_rack(app).call(env)
        env['warden'].user(:foo).should == 'foo user'
        env['warden'].user(:bar).should == 'bar user'
        env['warden'].user.should be_nil
      end
    end
  end # describe "authentication"
  
  describe "set user" do
    it "should store the user into the session" do
      env = env_with_params("/")
      app = lambda do |env|
        env['warden'].should be_authenticated(:pass)
        env['warden'].user.should == "Valid User"
        env['rack.session']["warden.user.default.key"].should == "Valid User"
        valid_response
      end
      setup_rack(app).call(env)
    end
  end

  describe "logout" do

    before(:each) do
      @env = env = env_with_params
      @env['rack.session'] = {"warden.user.default.key" => "default key", "warden.user.foo.key" => "foo key", :foo => "bar"}
      app = lambda do |e|
        e['warden'].logout(env['warden.spec.which_logout'])
        valid_response
      end
      @app = setup_rack(app)
    end
    
    it "should logout only the scoped foo user" do
      @env['warden.spec.which_logout'] = :foo
      @app.call(@env)
      @env['rack.session']['warden.user.default.key'].should == "default key"
      @env['rack.session']['warden.user.foo.key'].should be_nil
      @env['rack.session'][:foo].should == "bar"
    end
    
    it "should logout only the scoped default user" do 
      @env['warden.spec.which_logout'] = :default
      @app.call(@env)
      @env['rack.session']['warden.user.default.key'].should be_nil
      @env['rack.session']['warden.user.foo.key'].should == "foo key"
      @env['rack.session'][:foo].should == "bar"
    end
    
    it "should clear the session when no argument is given to logout" do
      @env['rack.session'].should_not be_nil
      app = lambda do |e|
        e['warden'].logout
        valid_response
      end
      setup_rack(app).call(@env)
      @env['rack.session'].should be_empty
    end
  end
  
end
