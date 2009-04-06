require File.dirname(__FILE__) + '/../spec_helper'

describe Rack::Auth::Manager do
  before(:each) do
    fail_app = @fail_app = lambda{|e| [401, {"Content-Type" => "text/plain"}, ["Fail App"]]}
    
    @app = Rack::Builder.new do
      use Rack::Session::Cookie, :secret => "Foo"
      use Rack::Auth::Manager, :failure_app => fail_app
      run lambda { |env| [200, {'Content-Type' => 'text/plain'}, 'OK'] }
    end
    @env = Rack::MockRequest.
      env_for('/', 'HTTP_VERSION' => '1.1', 'REQUEST_METHOD' => 'GET')
  end

  it "should insert a Base object into the rack env" do
    @app.call(@env)
    @env["rack.auth"].should be_an_instance_of(Rack::Auth::Proxy)
  end
  
  describe "user storage" do
    it "should take a user and store it in the provided session" do
      session = {}
      Rack::Auth::Manager.store_user("The User", "some_scope", session)
      session["user.some_scope"].should == "The User"
    end
    
    it "should use the use the user_session_key method to encode the user into the session" do
      session = {}
      Rack::Auth::Manager.should_receive(:user_session_key).with("The User").and_return(:keyed_user_for_session)
      Rack::Auth::Manager.store_user("The User", "some_scope", session)
      session["user.some_scope"].should == :keyed_user_for_session
    end
  end

  describe "thrown unauthenticated" do
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
    
    describe "Failure" do
      it "should respond with a 401 response if the strategy fails authentication" do
         env = env_with_params("/", :foo => "bar")
         app = lambda do |env|
           env['rack.auth'].authenticate(:failz)
           throw(:unauthenticated)
         end
         result = setup_rack(app, :failure_app => @fail_app).call(env)
         result.first.should == 401
      end
    
      it "should use the failure message given to the failure method" do
        env = env_with_params("/", {})
        app = lambda do |env|
          env['rack.auth'].authenticate(:failz)
          throw(:unauthenticated)
        end
        result = setup_rack(app, :failure_app => @fail_app).call(env)
        result.last.body.should == ["Fail App"]
      end
      
      it "should render the failure app when there's a failure" do
        app = lambda do |e| 
          throw(:unauthenticated) unless e['rack.auth'].authenticated?(:failz)
        end
        fail_app = lambda do |e|
          [401, {"Content-Type" => "text/plain"}, ["Failure App"]]
        end
        result = setup_rack(app, :failure_app => fail_app).call(env_with_params)
        result.last.body.should == ["Failure App"]
      end
    end # failure
    
  end
end
