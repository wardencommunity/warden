# encoding: utf-8
# frozen_string_literal: true
RSpec.describe Warden::Test::WardenHelpers do
  before :all do
    Warden.test_mode!
  end

  before do
    $captures = []
    @app = lambda{|_e| valid_response }
  end

  after do
    Warden.test_reset!
  end

  it{ expect(Warden).to respond_to(:test_mode!) }
  it{ expect(Warden).to respond_to(:on_next_request) }
  it{ expect(Warden).to respond_to(:test_reset!) }

  it "should execute the on_next_request block on the next request" do
    Warden.on_next_request do |warden|
      $captures << warden
    end

    setup_rack(@app).call(env_with_params)
    expect($captures.length).to eq(1)
    expect($captures.first).to be_an_instance_of(Warden::Proxy)
  end

  it "should execute many on_next_request blocks on the next request" do
    Warden.on_next_request{|_w| $captures << :first }
    Warden.on_next_request{|_w| $captures << :second }
    setup_rack(@app).call(env_with_params)
    expect($captures).to eq([:first, :second])
  end

  it "should not execute on_next_request blocks on subsequent requests" do
    app = setup_rack(@app)
    Warden.on_next_request{|_w| $captures << :first }
    app.call(env_with_params)
    expect($captures).to eq([:first])
    $captures.clear
    app.call(env_with_params)
    expect($captures).to be_empty
  end

  it "should allow me to set new_on_next_request items to execute in the same test" do
    app = setup_rack(@app)
    Warden.on_next_request{|_w| $captures << :first }
    app.call(env_with_params)
    expect($captures).to eq([:first])
    Warden.on_next_request{|_w| $captures << :second }
    app.call(env_with_params)
    expect($captures).to eq([:first, :second])
  end

  it "should remove the on_next_request items when test is reset" do
    app = setup_rack(@app)
    Warden.on_next_request{|_w| $captures << :first }
    Warden.test_reset!
    app.call(env_with_params)
    expect($captures).to eq([])
  end

  context "asset requests" do
    it "should not execute on_next_request blocks if this is an asset request" do
      app = setup_rack(@app)
      Warden.on_next_request{|_w| $captures << :first }
      app.call(env_with_params("/assets/fun.gif"))
      expect($captures).to eq([])
    end
  end

  context "background requests" do
    after do
      Warden.skip_background_requests = false
    end

    def background_request_env(path = "/search.json")
      env_with_params(path, {}, 'HTTP_SEC_FETCH_MODE' => 'cors', 'HTTP_ACCEPT' => 'application/json, */*')
    end

    def page_load_env(path = "/")
      env_with_params(path, {}, 'HTTP_SEC_FETCH_MODE' => 'navigate', 'HTTP_ACCEPT' => 'text/html,application/xhtml+xml')
    end

    it "should execute on_next_request blocks on background requests by default" do
      app = setup_rack(@app)
      Warden.on_next_request{|_w| $captures << :first }
      app.call(background_request_env)
      expect($captures).to eq([:first])
    end

    it "should keep on_next_request blocks queued until a page load when skip_background_requests is enabled" do
      Warden.skip_background_requests = true
      app = setup_rack(@app)
      Warden.on_next_request{|_w| $captures << :first }
      app.call(background_request_env)
      expect($captures).to eq([])
      app.call(page_load_env)
      expect($captures).to eq([:first])
    end

    it "should execute on_next_request blocks on browser requests asking for html" do
      Warden.skip_background_requests = true
      app = setup_rack(@app)
      Warden.on_next_request{|_w| $captures << :first }
      app.call(page_load_env)
      expect($captures).to eq([:first])
    end

    it "should execute on_next_request blocks on requests without Sec-Fetch-Mode" do
      Warden.skip_background_requests = true
      app = setup_rack(@app)
      Warden.on_next_request{|_w| $captures << :first }
      app.call(env_with_params("/api/things", {}, 'HTTP_ACCEPT' => 'application/json'))
      expect($captures).to eq([:first])
    end

    it "should accept a callable to customize the detection" do
      Warden.skip_background_requests = lambda{|env| env['PATH_INFO'] == "/background" }
      app = setup_rack(@app)
      Warden.on_next_request{|_w| $captures << :first }
      app.call(env_with_params("/background"))
      expect($captures).to eq([])
      app.call(env_with_params("/regular"))
      expect($captures).to eq([:first])
    end
  end
end
