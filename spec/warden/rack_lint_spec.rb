# frozen_string_literal: true
require 'spec_helper'
require 'rack/lint'

describe 'Rack::Lint compliance' do
  before(:each) do
    load_strategies
    RAS = Warden::Strategies unless defined?(RAS)

    RAS.add(:lint_redirect) do
      def authenticate!
        redirect!('/foo/bar', { foo: 'bar' }, permanent: true)
      end
    end

    RAS.add(:lint_custom) do
      def authenticate!
        custom!([521, { 'content-type' => 'text/plain' }, ['Custom Stuff']])
      end
    end
  end

  def lint_app(opts = {}, &block)
    inner = block || lambda { |_e| [200, { 'content-type' => 'text/plain' }, ['OK']] }
    opts = {
      failure_app: lambda { |_e| [401, { 'content-type' => 'text/plain' }, ['You Fail!']] },
      default_strategies: [:pass],
      legacy_env_key: false
    }.merge(opts)
    session = Warden::Spec::Helpers::Session

    Rack::Builder.new do
      use Rack::Lint
      use session
      use Rack::Lint
      use Warden::Manager, opts
      use Rack::Lint
      run inner
    end.to_app
  end

  def header_name(name)
    defined?(::Rack::Headers) ? name.downcase : name
  end

  it 'does not raise for a successful authentication' do
    app = lint_app do |e|
      e['warden.proxy'].authenticate!(:pass)
      [200, { 'content-type' => 'text/plain' }, ['OK']]
    end
    response = Rack::MockRequest.new(app).get('/')
    expect(response.status).to eq(200)
  end

  it 'does not raise when a strategy calls fail! and throws :warden' do
    app = lint_app do |e|
      e['warden.proxy'].authenticate!(:failz)
      raise 'should not reach here'
    end
    response = Rack::MockRequest.new(app).get('/')
    expect(response.status).to eq(401)
  end

  it 'does not raise for redirect! with permanent: true' do
    app = lint_app do |e|
      e['warden.proxy'].authenticate!(:lint_redirect)
      raise 'should not reach here'
    end
    response = Rack::MockRequest.new(app).get('/')
    expect(response.status).to eq(301)
    expect(response.headers[header_name('Location')]).to eq('/foo/bar?foo=bar')
    expect(response.headers[header_name('Content-Type')]).to eq('text/plain')
  end

  it 'does not raise for custom!' do
    app = lint_app do |e|
      e['warden.proxy'].authenticate!(:lint_custom)
      raise 'should not reach here'
    end
    response = Rack::MockRequest.new(app).get('/')
    expect(response.status).to eq(521)
  end

  it 'closes the discarded body when a downstream 401 is intercepted' do
    app = lint_app do |_e|
      [401, { 'content-type' => 'text/plain' }, ['Downstream Fail']]
    end
    response = Rack::MockRequest.new(app).get('/')
    expect(response.status).to eq(401)
    expect(response.body).to eq('You Fail!')
  end

  describe 'legacy_env_key: false' do
    it 'does not populate env["warden"] and exposes env["warden.proxy"]' do
      seen_env = nil
      app = lint_app do |e|
        seen_env = e
        [200, { 'content-type' => 'text/plain' }, ['OK']]
      end
      Rack::MockRequest.new(app).get('/')
      expect(seen_env.key?('warden')).to eq(false)
      expect(seen_env['warden.proxy']).to be_a(Warden::Proxy)
    end
  end

  describe 'legacy_env_key defaults to true (backwards compatibility)' do
    # Rack::Lint is intentionally left out of this one scenario: the default
    # behavior of writing env['warden'] with a non-String value is a known,
    # deliberate Rack::Lint violation kept for backwards compatibility.
    it 'still populates env["warden"] with the Proxy' do
      seen_env = nil
      inner = lambda { |e|
        seen_env = e
        [200, { 'content-type' => 'text/plain' }, ['OK']]
      }
      app = Rack::Builder.new do
        use Warden::Spec::Helpers::Session
        use Warden::Manager, default_strategies: [:pass],
                              failure_app: lambda { |_e| [401, {}, ['You Fail!']] }
        run inner
      end.to_app

      Rack::MockRequest.new(app).get('/')
      expect(seen_env['warden']).to be_a(Warden::Proxy)
    end
  end
end
