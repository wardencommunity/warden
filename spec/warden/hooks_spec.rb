require File.dirname(__FILE__) + '/../spec_helper'

describe "standard authentication hooks" do
  
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
      app = lambda{|e| e['warden'].set_user("foo"); valid_response}
      env = env_with_params
      setup_rack(app).call(env)
      env['warden.spec.hook.foo'].should == "run foo"
      env['warden.spec.hook.bar'].should == "run bar"
    end
  end
  
  describe "after_authenticate" do
    before(:each) do
      RAM = Warden::Manager unless defined?(RAM)
      RAM._after_authentication.clear
    end
    
    after(:each) do
      RAM._after_authentication.clear
    end
    
    it "should allow me to add an after_authetnication hook" do
      RAM.after_authentication{|user, auth, opts| "foo"}
      RAM._after_authentication.should have(1).item
    end
    
    it "should allow me to add multiple after_authetnication hooks" do
      RAM.after_authentication{|u,a,o| "bar"}
      RAM.after_authentication{|u,a,o| "baz"}
      RAM._after_authentication.should have(2).items
    end
    
    it "should run each after_authentication hook after authentication is run" do
      RAM.after_authentication{|u,a,o| a.env['warden.spec.hook.baz'] = "run baz"}
      RAM.after_authentication{|u,a,o| a.env['warden.spec.hook.paz'] = "run paz"}
      app = lambda{|e| e['warden'].authenticated?(:pass); valid_response}
      env = env_with_params
      setup_rack(app).call(env)
      env['warden.spec.hook.baz'].should == 'run baz'
      env['warden.spec.hook.paz'].should == 'run paz'
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
  describe "after_failure" do
    before(:each) do
      RAM = Warden::Manager unless defined?(RAM)
      RAM._after_failure.clear
    end
    
    after(:each) do
      RAM._after_failure.clear
    end
    
    it "should allow me to add a after_failure hook" do
      RAM.after_failure{|result| [-1, result[1], result[2]]}
      RAM._after_failure.should have(1).item
    end
    
    it "should allow me to add multiple after_failure hooks" do
      RAM.after_failure{|result| [-5, result[1], result[2]]}
      RAM.after_failure{|result| [-1, result[1], result[2]]}
      RAM._after_failure.should have(2).items
    end
    
    it "should run each before_failure hooks after failing" do
      RAM.after_failure{|result| result[0] = -42; result}
      RAM.after_failure{|result| result[1] = {:foo => :bar}; result}
      app = lambda{|e| e['warden'].authenticate!(:failz); valid_response}
      env = env_with_params
      result = setup_rack(app).call(env)
      result[0].should == -42
      result[1].should  == {:foo => :bar}
    end
  end
  
end