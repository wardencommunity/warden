require File.dirname(__FILE__) + '/../spec_helper'

describe Rack::Auth::Manager do

  it "should insert a Base object into the rack env" do
    env = env_with_params
    setup_rack(success_app).call(env)
    env["auth"].should be_an_instance_of(Rack::Auth::Proxy)
  end
  
  describe "user storage" do
    it "should take a user and store it in the provided session" do
      session = {}
      Rack::Auth::Manager._store_user("The User", session, "some_scope")
      session["user.some_scope.key"].should == "The User"
    end
    
    it "should use the use the user_session_key method to encode the user into the session" do
      session = {}
      Rack::Auth::Manager.should_receive(:user_session_key).with("The User").and_return(:keyed_user_for_session)
      Rack::Auth::Manager._store_user("The User", session, "some_scope")
      session["user.some_scope.key"].should == :keyed_user_for_session
    end
  end

  describe "thrown auth" do
    before(:each) do
      @basic_app = lambda{|env| [200,{'Content-Type' => 'text/plain'},'OK']}
      @authd_app = lambda do |e| 
        if e['auth'].authenticated? 
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
           env['auth'].authenticate(:failz)
           throw(:auth, :action => :unauthenticated)
         end
         result = setup_rack(app, :failure_app => @fail_app).call(env)
         result.first.should == 401
      end
    
      it "should use the failure message given to the failure method" do
        env = env_with_params("/", {})
        app = lambda do |env|
          env['auth'].authenticate(:failz)
          throw(:auth, :action => :unauthenticated)
        end
        result = setup_rack(app, :failure_app => @fail_app).call(env)
        result.last.body.should == ["You Fail!"]
      end
      
      it "should render the failure app when there's a failure" do
        app = lambda do |e| 
          throw(:auth, :action => :unauthenticated) unless e['auth'].authenticated?(:failz)
        end
        fail_app = lambda do |e|
          [401, {"Content-Type" => "text/plain"}, ["Failure App"]]
        end
        result = setup_rack(app, :failure_app => fail_app).call(env_with_params)
        result.last.body.should == ["Failure App"]
      end
    end # failure
    
  end
  
  describe "integrated strategies" do
    before(:each) do
      RAS = Rack::Auth::Strategies unless defined?(RAS)
      Rack::Auth::Strategies.clear!
      @app = setup_rack do |env|
        env['auth'].authenticate!(:foobar)
        [200, {"Content-Type" => "text/plain"}, ["Foo Is A Winna"]]        
      end
    end

    describe "redirecting" do
  
      it "should redirect with a message" do
        RAS.add(:foobar) do
          def authenticate!
            redirect!("/foo/bar", {:foo => "bar"}, :message => "custom redirection message")
          end
        end
        result = @app.call(env_with_params)
        result[0].should == 302
        result[1]["Location"].should == "/foo/bar?foo=bar"
        result[2].body.should == ["custom redirection message"]
      end
      
      it "should redirect with a default message" do
        RAS.add(:foobar) do
          def authenticate!
            redirect!("/foo/bar", {:foo => "bar"})
          end
        end
        result = @app.call(env_with_params)
        result[0].should == 302
        result[1]['Location'].should == "/foo/bar?foo=bar"
        result[2].body.should == ["You are being redirected to /foo/bar?foo=bar"]
      end
      
      it "should redirect with a permanent redirect" do
        RAS.add(:foobar) do
          def authenticate!
            redirect!("/foo/bar", {}, :permanent => true)
          end
        end
        result = @app.call(env_with_params)
        result[0].should == 301
      end
    end
  
    describe "failing" do
      it "should fail according to the failure app" do
        RAS.add(:foobar) do
          def authenticate!
            fail!
          end
        end
        env = env_with_params
        result = @app.call(env)
        result[0].should == 401
        result[2].body.should == ["You Fail!"]
        env['PATH_INFO'].should == "/unauthenticated"
      end
    end # failing
    
    describe "custom rack response" do
      it "should return a custom rack response" do
        RAS.add(:foobar) do
          def authenticate!
            custom!([523, {"Content-Type" => "text/plain", "Custom-Header" => "foo"}, ["Custom Stuff"]])
          end
        end
        result = @app.call(env_with_params)
        result[0].should == 523
        result[1]["Custom-Header"].should == "foo"
        result[2].body.should == ["Custom Stuff"]
      end
    end
  
    describe "success" do
      it "should pass through to the application when there is success" do
        RAS.add(:foobar) do
          def authenticate!
            success!("A User")
          end
        end
        env = env_with_params
        result = @app.call(env)
        result[0].should == 200
        result[2].body.should == ["Foo Is A Winna"]
      end
    end
  end # integrated strategies
end
