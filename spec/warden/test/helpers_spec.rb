# encoding: utf-8
# frozen_string_literal: true
RSpec.describe Warden::Test::Helpers do
  before do
    $captures = []
    Warden::Manager._after_set_user.clear
    Warden::Manager._before_logout.clear
    Warden::Manager.after_set_user do |user, _auth, opts|
      $captures << { :action => :set_user, :user => user }.merge(opts)
    end
    Warden::Manager.before_logout do |user, _auth, opts|
      $captures << { :action => :logout, :user => user }.merge(opts)
    end
  end

  after do
    Warden.test_reset!
    Warden::Manager._after_set_user.clear
    Warden::Manager._before_logout.clear
  end

  it "#login_as should log me in as a user" do
    user = "A User"
    login_as user
    app = lambda{|e|
      $captures << :run
      expect(e['warden']).to be_authenticated
      expect(e['warden'].user).to eq("A User")
      valid_response
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([
      { :action => :set_user, :event => :authentication, :scope => :default, :user => user },
      :run
    ])
  end

  it "#login_as with a scope should log me in as a user in that scope" do
    user = {:some => "user"}
    login_as user, :scope => :foo_scope
    app = lambda{|e|
      $captures << :run
      w = e['warden']
      expect(w).to be_authenticated(:foo_scope)
      expect(w.user(:foo_scope)).to eq(some: "user")
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([
      { :action => :set_user, :event => :authentication, :scope => :foo_scope, :user => user },
      :run
    ])
  end

  it "#login_as should login multiple users with different scopes" do
    user      = "A user"
    foo_user  = "A foo user"
    login_as user
    login_as foo_user, :scope => :foo
    app = lambda{|e|
      $captures << :run
      w = e['warden']
      expect(w.user).to eq("A user")
      expect(w.user(:foo)).to eq("A foo user")
      expect(w).to be_authenticated
      expect(w).to be_authenticated(:foo)
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([
      { :action => :set_user, :event => :authentication, :scope => :default, :user => user },
      { :action => :set_user, :event => :authentication, :scope => :foo, :user => foo_user },
      :run
    ])
  end

  it "#logout should log out all users" do
    user = "A user"
    foo  = "Foo"
    login_as user
    login_as foo, :scope => :foo
    logout
    app = lambda{|e|
      $captures << :run
      w = e['warden']
      expect(w.user).to be_nil
      expect(w.user(:foo)).to be_nil
      expect(w).not_to be_authenticated
      expect(w).not_to be_authenticated(:foo)
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([
      { :action => :set_user, :event => :authentication, :scope => :default, :user => user },
      { :action => :set_user, :event => :authentication, :scope => :foo, :user => foo },
      { :action => :logout, :scope => :default, :user => user },
      { :action => :logout, :scope => :foo, :user => foo },
      :run
    ])
  end

  it "#logout of a scope should logout that scope's specific user" do
    user = "A User"
    foo  = "Foo"
    login_as user
    login_as foo, :scope => :foo
    logout :foo
    app = lambda{|e|
      $captures << :run
      w = e['warden']
      expect(w.user).to eq("A User")
      expect(w.user(:foo)).to be_nil
      expect(w).not_to be_authenticated(:foo)
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([
      { :action => :set_user, :event => :authentication, :scope => :default, :user => user },
      { :action => :set_user, :event => :authentication, :scope => :foo, :user => foo },
      { :action => :logout, :scope => :foo, :user => foo },
      :run
    ])
  end

  it "#logout can log out of multiple scopes, in the order specified" do
    user = "A user"
    foo  = "Foo"
    login_as user
    login_as foo, :scope => :foo
    logout :foo, :default
    app = lambda{|e|
      $captures << :run
      w = e['warden']
      expect(w.user).to be_nil
      expect(w.user(:foo)).to be_nil
      expect(w).not_to be_authenticated
      expect(w).not_to be_authenticated(:foo)
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([
      { :action => :set_user, :event => :authentication, :scope => :default, :user => user },
      { :action => :set_user, :event => :authentication, :scope => :foo, :user => foo },
      { :action => :logout, :scope => :foo, :user => foo },
      { :action => :logout, :scope => :default, :user => user },
      :run
    ])
  end

  it "#logout with no users logged in should be a noop" do
    logout
    app = lambda{|e|
      $captures << :run
      w = e['warden']
      expect(w.user).to be_nil
      expect(w.user(:foo)).to be_nil
      expect(w).not_to be_authenticated
      expect(w).not_to be_authenticated(:foo)
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([:run])
  end

  it "#unlogin should cause the user to be fetched from the session, but not log out" do
    user = "A User"
    login_as user
    unlogin
    app = lambda{|e|
      $captures << :run
      expect(e['warden']).to be_authenticated
      expect(e['warden'].user).to eq("A User")
      valid_response
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([
      { :action => :set_user, :event => :authentication, :scope => :default, :user => user },
      :run,
      { :action => :set_user, :event => :fetch, :scope => :default, :user => user }
    ])
  end

  it "#unlogin of a scope should cause that scope's specific user to be fetched from the session, but not log out" do
    user = "A User"
    foo  = "A foo user"
    login_as user
    login_as foo, :scope => :foo
    unlogin :foo
    app = lambda{|e|
      $captures << :run
      w = e['warden']
      expect(w.user).to eq("A User")
      expect(w.user(:foo)).to eq("A foo user")
      expect(w).to be_authenticated(:foo)
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([
      { :action => :set_user, :event => :authentication, :scope => :default, :user => user },
      { :action => :set_user, :event => :authentication, :scope => :foo, :user => foo },
      :run,
      { :action => :set_user, :event => :fetch, :scope => :foo, :user => foo }
    ])
  end

  it "#unlogin can handle multiple scopes, without affecting fetch order" do
    user = "A User"
    foo  = "A foo user"
    login_as user
    login_as foo, :scope => :foo
    unlogin :foo, :default
    app = lambda{|e|
      $captures << :run
      w = e['warden']
      expect(w.user).to eq("A User")
      expect(w.user(:foo)).to eq("A foo user")
      expect(w).to be_authenticated(:foo)
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([
      { :action => :set_user, :event => :authentication, :scope => :default, :user => user },
      { :action => :set_user, :event => :authentication, :scope => :foo, :user => foo },
      :run,
      { :action => :set_user, :event => :fetch, :scope => :default, :user => user },
      { :action => :set_user, :event => :fetch, :scope => :foo, :user => foo }
    ])
  end

  it "#unlogin with no users logged in should be a noop" do
    unlogin
    app = lambda{|e|
      $captures << :run
      w = e['warden']
      expect(w.user).to be_nil
      expect(w.user(:foo)).to be_nil
      expect(w).not_to be_authenticated
      expect(w).not_to be_authenticated(:foo)
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([:run])
  end

  describe "#asset_paths" do
    it "should default asset_paths to anything asset path regex" do
      expect(Warden.asset_paths).to eq([/^\/assets\//]      )
    end
  end
end
