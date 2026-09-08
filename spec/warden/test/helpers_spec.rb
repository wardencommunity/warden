# encoding: utf-8
# frozen_string_literal: true
RSpec.describe Warden::Test::Helpers do
  before{ $captures = [] }
  after{ Warden.test_reset! }

  it "should log me in as a user" do
    user = "A User"
    login_as user
    app = lambda{|e|
      $captures << :run
      expect(e['warden']).to be_authenticated
      expect(e['warden'].user).to eq("A User")
      valid_response
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([:run])
  end

  it "should log me in as a user of a given scope" do
    user = {:some => "user"}
    login_as user, :scope => :foo_scope
    app = lambda{|e|
      $captures << :run
      w = e['warden']
      expect(w).to be_authenticated(:foo_scope)
      expect(w.user(:foo_scope)).to eq(some: "user")
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([:run])
  end

  it "should login multiple users with different scopes" do
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
    expect($captures).to eq([:run])
  end

  it "should log out all users" do
    user = "A user"
    foo  = "Foo"
    login_as user
    login_as foo, :scope => :foo
    app = lambda{|e|
      $captures << :run
      w = e['warden']
      expect(w.user).to eq("A user")
      expect(w.user(:foo)).to eq("Foo")
      w.logout
      expect(w.user).to be_nil
      expect(w.user(:foo)).to be_nil
      expect(w).not_to be_authenticated
      expect(w).not_to be_authenticated(:foo)
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([:run])
  end

  it "should logout a specific user" do
    user = "A User"
    foo  = "Foo"
    login_as user
    login_as foo, :scope => :foo
    app = lambda{|e|
      $captures << :run
      w = e['warden']
      w.logout :foo
      expect(w.user).to eq("A User")
      expect(w.user(:foo)).to be_nil
      expect(w).not_to be_authenticated(:foo)
    }
    setup_rack(app).call(env_with_params)
    expect($captures).to eq([:run])
  end

  it "should persist authentication across multiple requests" do
    user = "A User"
    session = {}
    login_as user
    app = setup_rack(lambda { |e|
      $captures << e['warden'].user
      valid_response
    })
    app.call(env_with_params("/", {}, "rack.session" => session))
    app.call(env_with_params("/", {}, "rack.session" => session))
    expect($captures).to eq(["A User", "A User"])
  end

  it "should not lose authentication when another session makes a concurrent request" do
    alice = "Alice"
    bob   = "Bob"

    alice_session = {}
    bob_session   = {}

    app = setup_rack(lambda { |e|
      $captures << e['warden'].user
      valid_response
    })

    # 1. Alice logs in and visits a page — her session is established
    login_as alice
    app.call(env_with_params("/", {}, "rack.session" => alice_session))

    # 2. Bob logs in
    login_as bob

    # 3. A background request from Alice's session (e.g. Turbo Frame fetch)
    app.call(env_with_params("/turbo-frame", {}, "rack.session" => alice_session))

    # 4. Bob's session makes its first request
    app.call(env_with_params("/", {}, "rack.session" => bob_session))

    expect($captures).to eq(["Alice", "Alice", "Bob"])
  end

  it "should allow switching users with logout in between" do
    session = {}
    app = setup_rack(lambda { |e|
      $captures << e['warden'].user
      valid_response
    })

    login_as "Alice"
    app.call(env_with_params("/", {}, "rack.session" => session))

    logout
    login_as "Bob"
    app.call(env_with_params("/", {}, "rack.session" => session))

    expect($captures).to eq(["Alice", "Bob"])
  end

  it "should clear persistent state on logout" do
    user = "A User"
    login_as user
    expect(Warden._test_users).not_to be_empty
    logout
    expect(Warden._test_users).to be_empty
  end

  it "should clear only the specified scope on logout" do
    login_as "Default User"
    login_as "Foo User", scope: :foo
    logout :foo
    expect(Warden._test_users.keys).to eq([nil])
  end

  describe "#asset_paths" do
    it "should default asset_paths to anything asset path regex" do
      expect(Warden.asset_paths).to eq([/^\/assets\//]      )
    end
  end
end
