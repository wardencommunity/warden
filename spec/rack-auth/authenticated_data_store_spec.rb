require File.dirname(__FILE__) + '/../spec_helper'

describe "authenticated data store" do
  
  before(:each) do
    @env = env_with_params
    @env['rack.session'] = {
        "rack-auth.user.foo.key"      => "foo user", 
        "rack-auth.user.default.key"  => "default user", 
        :foo => "bar"
    }
  end
  
  it "should store data for the default scope" do
    app = lambda do |e|
      e['rack-auth'].should be_authenticated(:pass)
      e['rack-auth'].should be_authenticated(:pass, :scope => :foo)
      
      # Store the data for :deafult
      e['rack-auth'].data[:key] = "value"
      valid_response
    end
    setup_rack(app).call(@env)
    @env['rack.session']['rack-auth.user.default.data'].should == {:key => "value"}
    @env['rack.session']['rack-auth.user.foo.data'].should be_nil
  end
  
  it "should store data for the foo user" do
    app = lambda do |e|
      e['rack-auth'].data(:foo)[:key] = "value"
      valid_response
    end
    setup_rack(app).call(@env)
    @env['rack.session']['rack-auth.user.foo.data'].should == {:key => "value"}
  end
  
  it "should store the data seperately" do
    app = lambda do |e|
      e['rack-auth'].data[:key] = "value"
      e['rack-auth'].data(:foo)[:key] = "another value"
      valid_response
    end
    setup_rack(app).call(@env)
    @env['rack.session']['rack-auth.user.default.data'].should == {:key => "value"}
    @env['rack.session']['rack-auth.user.foo.data'    ].should == {:key => "another value"}
  end
  
  it "should clear the foo scoped data when foo logs out" do
    app = lambda do |e|
      e['rack-auth'].data[:key] = "value"
      e['rack-auth'].data(:foo)[:key] = "another value"
      e['rack-auth'].logout(:foo)
      valid_response
    end
    setup_rack(app).call(@env)
    @env['rack.session']['rack-auth.user.default.data'].should == {:key => "value"}
    @env['rack.session']['rack-auth.user.foo.data'    ].should be_nil
  end
  
  it "should clear out the default data when :default logs out" do
    app = lambda do |e|
      e['rack-auth'].data[:key] = "value"
      e['rack-auth'].data(:foo)[:key] = "another value"
      e['rack-auth'].logout(:default)
      valid_response
    end
    setup_rack(app).call(@env)
    @env['rack.session']['rack-auth.user.default.data'].should be_nil
    @env['rack.session']['rack-auth.user.foo.data'    ].should == {:key => "another value"}
  end
  
  it "should clear out all data when a general logout is performed" do
    app = lambda do |e|
      e['rack-auth'].data[:key] = "value"
      e['rack-auth'].data(:foo)[:key] = "another value"
      e['rack-auth'].logout
      valid_response
    end
    setup_rack(app).call(@env)
    @env['rack.session']['rack-auth.user.default.data'].should be_nil
    @env['rack.session']['rack-auth.user.foo.data'    ].should be_nil
  end
  
  it "should logout multuiple personas at once" do
    @env['rack.session']['rack-auth.user.bar.key'] = "bar user"
    
    app = lambda do |e|
      e['rack-auth'].data[:key] = "value"
      e['rack-auth'].data(:foo)[:key] = "another value"
      e['rack-auth'].data(:bar)[:key] = "yet another"
      e['rack-auth'].logout(:bar, :default)
      valid_response
    end
    setup_rack(app).call(@env)
    @env['rack.session']['rack-auth.user.default.data'].should be_nil
    @env['rack.session']['rack-auth.user.foo.data'    ].should == {:key => "another value"}
    @env['rack.session']['rack-auth.user.bar.data'    ].should be_nil
  end
  
  it "should not store data for a user who is not logged in" do
    @env['rack.session']
    app = lambda do |e|
      e['rack-auth'].data(:not_here)[:key] = "value"
      valid_response
    end
    
    lambda do
      setup_rack(app).call(@env)
    end.should raise_error(Rack::Auth::NotAuthenticated)
  end
end