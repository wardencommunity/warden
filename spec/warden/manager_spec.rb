# encoding: utf-8
require 'spec_helper'

describe Warden::Manager do

  before(:all) do
    load_strategies
  end

  it "should insert a Proxy object into the rack env" do
    env = env_with_params
    setup_rack(success_app).call(env)
    env["warden"].should be_an_instance_of(Warden::Proxy)
  end

  describe "thrown auth" do
    before(:each) do
      @basic_app = lambda{|env| [200,{'Content-Type' => 'text/plain'},'OK']}
      @authd_app = lambda do |e|
        if e['warden'].authenticated?
          [200,{'Content-Type' => 'text/plain'},"OK"]
        else
          [401,{'Content-Type' => 'text/plain'},"Fail From The App"]
        end
      end
      @env = Rack::MockRequest.
        env_for('/', 'HTTP_VERSION' => '1.1', 'REQUEST_METHOD' => 'GET')
    end # before(:each)

    describe "Failure" do
      it "should respond with a 401 response if the strategy fails authentication" do
         env = env_with_params("/", :foo => "bar")
         app = lambda do |_env|
           _env['warden'].authenticate(:failz)
           throw(:warden, :action => :unauthenticated)
         end
         result = setup_rack(app, :failure_app => @fail_app).call(env) # TODO: What is @fail_app?
         result.first.should be(401)
      end

      it "should use the failure message given to the failure method" do
        env = env_with_params("/", {})
        app = lambda do |_env|
          _env['warden'].authenticate(:failz)
          throw(:warden)
        end
        result = setup_rack(app, :failure_app => @fail_app).call(env) # TODO: What is @fail_app?
        result.last.should eq(["You Fail!"])
      end

      it "should set the message from the winning strategy in warden.options hash" do
        env = env_with_params("/", {})
        app = lambda do |_env|
          _env['warden'].authenticate(:failz)
          throw(:warden)
        end
        setup_rack(app, :failure_app => @fail_app).call(env) # TODO: What is @fail_app?
        env["warden.options"][:message].should eq("The Fails Strategy Has Failed You")
      end

      it "should render the failure app when there's a failure" do
        app = lambda do |e|
          throw(:warden, :action => :unauthenticated) unless e['warden'].authenticated?(:failz)
        end
        fail_app = lambda do |e|
          [401, {"Content-Type" => "text/plain"}, ["Failure App"]]
        end
        result = setup_rack(app, :failure_app => fail_app).call(env_with_params)
        result.last.should eq(["Failure App"])
      end

      it "should call failure app if warden is thrown even after successful authentication" do
        env = env_with_params("/", {})
        app = lambda do |_env|
          _env['warden'].authenticate(:pass)
          throw(:warden)
        end
        result = setup_rack(app, :failure_app => @fail_app).call(env)
        result.first.should be(401)
        result.last.should eq(["You Fail!"])
      end

      it "should set the attempted url in warden.options hash" do
        env = env_with_params("/access/path", {})
        app = lambda do |_env|
          _env['warden'].authenticate(:pass)
          throw(:warden)
        end
        result = setup_rack(app, :failure_app => @fail_app).call(env) # TODO: What is @fail_app?
        result.first.should be(401)
        env["warden.options"][:attempted_path].should eq("/access/path")
      end

      it "should catch a resubmitted request" do
        # this is a bit convoluted. but it's occurred in the field with Rack::OpenID
        $count = 0
        $throw_count = 0
        env = env_with_params("/foo")
        class ::ResubmittingMiddleware
          @@app = nil
          def initialize(app)
            @@app = app
          end

          def self.call(env)
            if $count > 1
              Rack::Response.new("Bad", 401)
            else
              $count += 1
              @@app.call(env)
            end
          end

          def call(env)
            $count += 1
            @@app.call(env)
          end

        end

        app = lambda do |e|
          $throw_count += 1
          throw(:warden)
        end

        builder = Rack::Builder.new do
          use ResubmittingMiddleware
          use Warden::Manager do |config|
            config.failure_app = ResubmittingMiddleware
          end
          run app
        end

        result = builder.to_app.call(env)
        result[0].should be(401)
        result[2].body.should eq(["Bad"])
        $throw_count.should be(2)
      end

      it "should use the default scopes action when a bare throw is used" do
         env = env_with_params("/", :foo => "bar")
         action = nil

         failure = lambda do |_env|
           action = _env['PATH_INFO'] 
           [401, {}, ['fail']]
         end

         app = lambda do |_env|
           throw(:warden)
         end
         result = setup_rack(app,
                             :failure_app => failure,
                             :configurator => lambda{ |c| c.scope_defaults(:default, :action => 'my_action', :strategies => [:password]) }
                            ).call(env)

         action.should eq("/my_action")
         result.first.should be(401)
      end
    end # failure
  end

  describe "integrated strategies" do
    before(:each) do
      RAS = Warden::Strategies unless defined?(RAS)
      Warden::Strategies.clear!
      @app = setup_rack do |env|
        env['warden'].authenticate!(:foobar)
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
        result[0].should be(302)
        result[1]["Location"].should eq("/foo/bar?foo=bar")
        result[2].should eq(["custom redirection message"])
      end

      it "should redirect with a default message" do
        RAS.add(:foobar) do
          def authenticate!
            redirect!("/foo/bar", {:foo => "bar"})
          end
        end
        result = @app.call(env_with_params)
        result[0].should be(302)
        result[1]['Location'].should eq("/foo/bar?foo=bar")
        result[2].should eq(["You are being redirected to /foo/bar?foo=bar"])
      end

      it "should redirect with a permanent redirect" do
        RAS.add(:foobar) do
          def authenticate!
            redirect!("/foo/bar", {}, :permanent => true)
          end
        end
        result = @app.call(env_with_params)
        result[0].should be(301)
      end

      it "should redirect with a content type" do
        RAS.add(:foobar) do
          def authenticate!
            redirect!("/foo/bar", {:foo => "bar"}, :content_type => "text/xml")
          end
        end
        result = @app.call(env_with_params)
        result[0].should be(302)
        result[1]["Location"].should eq("/foo/bar?foo=bar")
        result[1]["Content-Type"].should eq("text/xml")
      end

      it "should redirect with a default content type" do
        RAS.add(:foobar) do
          def authenticate!
            redirect!("/foo/bar", {:foo => "bar"})
          end
        end
        result = @app.call(env_with_params)
        result[0].should be(302)
        result[1]["Location"].should eq("/foo/bar?foo=bar")
        result[1]["Content-Type"].should eq("text/plain")
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
        result[0].should be(401)
        result[2].should eq(["You Fail!"])
        env['PATH_INFO'].should eq("/unauthenticated")
      end

      it "should allow you to customize the response" do
        app = lambda do |e|
          e['warden'].custom_failure!
          [401,{'Content-Type' => 'text/plain'},["Fail From The App"]]
        end
        env = env_with_params
        result = setup_rack(app).call(env)
        result[0].should be(401)
        result[2].should eq(["Fail From The App"])
      end

      it "should allow you to customize the response without the explicit call to custom_failure! if not intercepting 401" do
        app = lambda do |e|
          [401,{'Content-Type' => 'text/plain'},["Fail From The App"]]
        end
        env = env_with_params
        result = setup_rack(app, :intercept_401 => false).call(env)
        result[0].should be(401)
        result[2].should eq(["Fail From The App"])
      end

      it "should render the failure application for a 401 if no custom_failure flag is set" do
        app = lambda do |e|
          [401,{'Content-Type' => 'text/plain'},["Fail From The App"]]
        end
        result = setup_rack(app).call(env_with_params)
        result[0].should be(401)
        result[2].should eq(["You Fail!"])
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
        result[0].should be(523)
        result[1]["Custom-Header"].should eq("foo")
        result[2].should eq(["Custom Stuff"])
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
        result[0].should be(200)
        result[2].should eq(["Foo Is A Winna"])
      end
    end
  end # integrated strategies

  it "should allow me to set a different default scope for warden" do
    Rack::Builder.new do
      use Warden::Manager, :default_scope => :default do |manager|
        manager.default_scope.should be(:default)
        manager.default_scope = :other
        manager.default_scope.should be(:other)
      end
    end
  end

  it "should allow me to access strategies through manager" do
    Rack::Builder.new do
      use Warden::Manager do |manager|
        manager.strategies.should be(Warden::Strategies)
      end
    end
  end
end
