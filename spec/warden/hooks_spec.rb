# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

describe "standard authentication hooks" do

  before(:all) do
    load_strategies
  end

  describe "after_set_user" do
    before(:each) do
      RAM = Warden::Manager unless defined?(RAM)
      RAM._after_set_user.clear
    end

    after(:each) do
      RAM._after_set_user.clear
    end

    it "should allow me to add an after_set_user hook" do
      RAM.after_set_user do |user, auth, opts|
        "boo"
      end
      RAM._after_set_user.should have(1).item
    end

    it "should allow me to add multiple after_set_user hooks" do
      RAM.after_set_user{|user, auth, opts| "foo"}
      RAM.after_set_user{|u,a| "bar"}
      RAM._after_set_user.should have(2).items
    end

    it "should run each after_set_user hook after the user is set" do
      RAM.after_set_user{|u,a,o| a.env['warden.spec.hook.foo'] = "run foo"}
      RAM.after_set_user{|u,a,o| a.env['warden.spec.hook.bar'] = "run bar"}
      RAM.after_set_user{|u,a,o| a.logout}
      app = lambda do |e|
        e['warden'].set_user("foo")
        valid_response
      end
      env = env_with_params
      setup_rack(app).call(env)
      env['warden'].user.should be_nil
      env['warden.spec.hook.foo'].should == "run foo"
      env['warden.spec.hook.bar'].should == "run bar"
    end

    it "should not run the event specified with except" do
      RAM.after_set_user(:except => :set_user){|u,a,o| fail}
      app = lambda do |e|
        e['warden'].set_user("foo")
        valid_response
      end
      env = env_with_params
      setup_rack(app).call(env)
    end

    it "should only run the event specified with only" do
      RAM.after_set_user(:only => :set_user){|u,a,o| fail}
      app = lambda do |e|
        e['warden'].authenticate(:pass)
        valid_response
      end
      env = env_with_params
      setup_rack(app).call(env)
    end

    context "after_authentication" do
      it "should be a wrapper to after_set_user behavior" do
        RAM.after_authentication{|u,a,o| a.env['warden.spec.hook.baz'] = "run baz"}
        RAM.after_authentication{|u,a,o| a.env['warden.spec.hook.paz'] = "run paz"}
        RAM.after_authentication{|u,a,o| o[:event].should == :authentication }
        app = lambda{|e| e['warden'].authenticate(:pass); valid_response}
        env = env_with_params
        setup_rack(app).call(env)
        env['warden.spec.hook.baz'].should == 'run baz'
        env['warden.spec.hook.paz'].should == 'run paz'
      end

      it "should not be invoked on default after_set_user scenario" do
        RAM.after_authentication{|u,a,o| fail}
        app = lambda do |e|
          e['warden'].set_user("foo")
          valid_response
        end
        env = env_with_params
        setup_rack(app).call(env)
      end
    end

    context "after_fetch" do
      it "should be a wrapper to after_set_user behavior" do
        RAM.after_fetch{|u,a,o| a.env['warden.spec.hook.baz'] = "run baz"}
        RAM.after_fetch{|u,a,o| a.env['warden.spec.hook.paz'] = "run paz"}
        RAM.after_fetch{|u,a,o| o[:event].should == :fetch }
        env = env_with_params
        setup_rack(lambda { |e| valid_response }).call(env)
        env['rack.session']['warden.user.default.key'] = "Foo"
        env['warden'].user.should == "Foo"
        env['warden.spec.hook.baz'].should == 'run baz'
        env['warden.spec.hook.paz'].should == 'run paz'
      end

      it "should not be invoked on default after_set_user scenario" do
        RAM.after_fetch{|u,a,o| fail}
        app = lambda do |e|
          e['warden'].set_user("foo")
          valid_response
        end
        env = env_with_params
        setup_rack(app).call(env)
      end

      it "should not be invoked if fetched user is nil" do
        RAM.after_fetch{|u,a,o| fail}
        env = env_with_params
        setup_rack(lambda { |e| valid_response }).call(env)
        env['rack.session']['warden.user.default.key'] = nil
        env['warden'].user.should be_nil
      end
    end

  end

  describe "before_failure" do
    before(:each) do
      RAM = Warden::Manager unless defined?(RAM)
      RAM._before_failure.clear
    end

    after(:each) do
      RAM._before_failure.clear
    end

    it "should allow me to add a before_failure hook" do
      RAM.before_failure{|env, opts| "foo"}
      RAM._before_failure.should have(1).item
    end

    it "should allow me to add multiple before_failure hooks" do
      RAM.before_failure{|env, opts| "foo"}
      RAM.before_failure{|env, opts| "bar"}
      RAM._before_failure.should have(2).items
    end

    it "should run each before_failure hooks before failing" do
      RAM.before_failure{|e,o| e['warden.spec.before_failure.foo'] = "foo"}
      RAM.before_failure{|e,o| e['warden.spec.before_failure.bar'] = "bar"}
      app = lambda{|e| e['warden'].authenticate!(:failz); valid_response}
      env = env_with_params
      setup_rack(app).call(env)
      env['warden.spec.before_failure.foo'].should == "foo"
      env['warden.spec.before_failure.bar'].should  == "bar"
    end
  end

  describe "before_logout" do
    before(:each) do
      RAM = Warden::Manager unless defined?(RAM)
      RAM._before_logout.clear
    end

    after(:each) do
      RAM._before_logout.clear
    end

    it "should allow me to add an before_logout hook" do
      RAM.before_logout{|user, auth, scopes| "foo"}
      RAM._before_logout.should have(1).item
    end

    it "should allow me to add multiple after_authentication hooks" do
      RAM.before_logout{|u,a,o| "bar"}
      RAM.before_logout{|u,a,o| "baz"}
      RAM._before_logout.should have(2).items
    end

    it "should run each before_logout hook before logout is run" do
      RAM.before_logout{|u,a,o| a.env['warden.spec.hook.lorem'] = "run lorem"}
      RAM.before_logout{|u,a,o| a.env['warden.spec.hook.ipsum'] = "run ipsum"}
      app = lambda{|e| e['warden'].authenticate(:pass); valid_response}
      env = env_with_params
      setup_rack(app).call(env)
      env['warden'].logout
      env['warden.spec.hook.lorem'].should == 'run lorem'
      env['warden.spec.hook.ipsum'].should == 'run ipsum'
    end

    it "should run before_logout hook for a specified scope" do
      RAM.before_logout(:scope => :scope1){|u,a,o| a.env["warden.spec.hook.a"] << :scope1 }
      RAM.before_logout(:scope => [:scope2]){|u,a,o| a.env["warden.spec.hook.b"] << :scope2 }

      app = lambda do |e|
        e['warden'].authenticate(:pass, :scope => :scope1)
        e['warden'].authenticate(:pass, :scope => :scope2)
        valid_response
      end
      env = env_with_params
      env["warden.spec.hook.a"] ||= []
      env["warden.spec.hook.b"] ||= []
      setup_rack(app).call(env)

      env['warden'].logout(:scope1)
      env['warden.spec.hook.a'].should == [:scope1]
      env['warden.spec.hook.b'].should == []

      env['warden'].logout(:scope2)
      env['warden.spec.hook.a'].should == [:scope1]
      env['warden.spec.hook.b'].should == [:scope2]
    end
  end

end
