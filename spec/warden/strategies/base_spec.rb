# frozen_string_literal: true
# encoding: utf-8
require 'spec_helper'

describe Warden::Strategies::Base do

  before(:each) do
    RAS = Warden::Strategies unless defined?(RAS)
    Warden::Strategies.clear!
  end

  describe "headers" do
    it "should have headers" do
      Warden::Strategies.add(:foo) do
        def authenticate!
          headers("foo" => "bar")
        end
      end
      strategy = Warden::Strategies[:foo].new(env_with_params)
      strategy._run!
      expect(strategy.headers["foo"]).to eq("bar")
    end

    it "should allow us to clear the headers" do
      Warden::Strategies.add(:foo) do
        def authenticate!
          headers("foo" => "bar")
        end
      end
      strategy = Warden::Strategies[:foo].new(env_with_params)
      strategy._run!
      expect(strategy.headers["foo"]).to eq("bar")
      strategy.headers.clear
      expect(strategy.headers).to be_empty
    end
  end

  it "should have a user object" do
    RAS.add(:foobar) do
      def authenticate!
        success!("foo")
      end
    end
    strategy = RAS[:foobar].new(env_with_params)
    strategy._run!
    expect(strategy.user).to eq("foo")
  end

  it "should be performed after run" do
    RAS.add(:foobar) do
      def authenticate!; end
    end
    strategy = RAS[:foobar].new(env_with_params)
    expect(strategy).not_to be_performed
    strategy._run!
    expect(strategy).to be_performed
    strategy.clear!
    expect(strategy).not_to be_performed
  end

  it "should set the scope when initialized with one" do
    RAS.add(:foobar) do
      def authenticate!; end
    end
    strategy = RAS[:foobar].new(env_with_params, :user)
    expect(strategy.scope).to eq(:user)
  end

  it "should allow you to set a message" do
    RAS.add(:foobar) do
      def authenticate!
        self.messages = ["foo message"]
      end
    end
    strategy = RAS[:foobar].new(env_with_params)
    strategy._run!
    expect(strategy.messages).to eq(["foo message"])
  end

  it "should provide access to the errors" do
    RAS.add(:foobar) do
      def authenticate!
        errors.add(:foo, "foo has an error")
      end
    end
    env = env_with_params
    env['warden'] = Warden::Proxy.new(env, Warden::Manager.new({}))
    strategy = RAS[:foobar].new(env)
    strategy._run!
    expect(strategy.errors.on(:foo)).to eq(["foo has an error"])
  end

  describe "halting" do
    it "should allow you to halt a strategy" do
      RAS.add(:foobar) do
        def authenticate!
          halt!
        end
      end
      str = RAS[:foobar].new(env_with_params)
      str._run!
      expect(str).to be_halted
    end

    it "should not be halted if halt was not called" do
      RAS.add(:foobar) do
        def authenticate!
          "foo"
        end
      end
      str = RAS[:foobar].new(env_with_params)
      str._run!
      expect(str).not_to be_halted
    end
  end

  describe "pass" do
    it "should allow you to pass" do
      RAS.add(:foobar) do
        def authenticate!
          pass
        end
      end
      str = RAS[:foobar].new(env_with_params)
      str._run!
      expect(str).not_to be_halted
      expect(str.user).to be_nil
    end
  end

  describe "redirect" do
    it "should allow you to set a redirection" do
      RAS.add(:foobar) do
        def authenticate!
          redirect!("/foo/bar")
        end
      end
      str = RAS[:foobar].new(env_with_params)
      str._run!
      expect(str.user).to be_nil
    end

    it "should mark the strategy as halted when redirecting" do
      RAS.add(:foobar) do
        def authenticate!
          redirect!("/foo/bar")
        end
      end
      str = RAS[:foobar].new(env_with_params)
      str._run!
      expect(str).to be_halted
    end

    it "should escape redirected url parameters" do
      RAS.add(:foobar) do
        def authenticate!
          redirect!("/foo/bar", :foo => "bar")
        end
      end
      str = RAS[:foobar].new(env_with_params)
      str._run!
      expect(str.headers["Location"]).to eq("/foo/bar?foo=bar")
    end

    it "should allow you to set a message" do
      RAS.add(:foobar) do
        def authenticate!
          redirect!("/foo/bar", {:foo => "bar"}, :message => "You are being redirected foo")
        end
      end
      str = RAS[:foobar].new(env_with_params)
      str._run!
      expect(str.headers["Location"]).to eq("/foo/bar?foo=bar")
      expect(str.messages).to eq(["You are being redirected foo"])
    end

    it "should warn when using message instead of messages" do
      RAS.add(:foobar) do
        def authenticate!
          redirect!("/foo/bar", {:foo => "bar"}, :message => "You are being redirected foo")
        end
      end

      expect {
        str = RAS[:foobar].new(env_with_params)
        str._run!
      }.to output(/NOTE: Sending :message to redirect! is deprecated, use :messages instead./).to_stderr
    end

    it "should allow you to set messages" do
      RAS.add(:foobar) do
        def authenticate!
          redirect!("/foo/bar", {:foo => "bar"}, :messages => "You are being redirected foo")
        end
      end
      str = RAS[:foobar].new(env_with_params)
      str._run!
      expect(str.headers["Location"]).to eq("/foo/bar?foo=bar")
      expect(str.messages).to eq(["You are being redirected foo"])
    end

    it "should set the action as :redirect" do
      RAS.add(:foobar) do
        def authenticate!
          redirect!("/foo/bar", {:foo => "bar"}, :messages => "foo")
        end
      end
      str = RAS[:foobar].new(env_with_params)
      str._run!
      expect(str.result).to be(:redirect)
    end
  end

  describe "failure" do
    before(:each) do
      RAS.add(:hard_fail) do
        def authenticate!
          fail!("You are not cool enough")
        end
      end

      RAS.add(:soft_fail) do
        def authenticate!
          fail("You are too soft")
        end
      end
      @hard = RAS[:hard_fail].new(env_with_params)
      @soft = RAS[:soft_fail].new(env_with_params)
    end

    it "should allow you to fail hard" do
      @hard._run!
      expect(@hard.user).to be_nil
    end

    it "should halt the strategies when failing hard" do
      @hard._run!
      expect(@hard).to be_halted
    end

    it "should allow you to set a message when failing hard" do
      @hard._run!
      expect(@hard.messages).to eq(["You are not cool enough"])
    end

    it "should set the action as :failure when failing hard" do
      @hard._run!
      expect(@hard.result).to be(:failure)
    end

    it "should allow you to fail soft" do
      @soft._run!
      expect(@soft.user).to be_nil
    end

    it "should not halt the strategies when failing soft" do
      @soft._run!
      expect(@soft).not_to be_halted
    end

    it "should allow you to set a message when failing soft" do
      @soft._run!
      expect(@soft.messages).to eq(["You are too soft"])
    end

    it "should set the action as :failure when failing soft" do
      @soft._run!
      expect(@soft.result).to be(:failure)
    end
  end

  describe "success" do
    before(:each) do
      RAS.add(:foobar) do
        def authenticate!
          success!("Foo User", "Welcome to the club!")
        end
      end
      @str = RAS[:foobar].new(env_with_params)
    end

    it "should allow you to succeed" do
      @str._run!
    end

    it "should be authenticated after success" do
      @str._run!
      expect(@str.user).not_to be_nil
    end

    it "should allow you to set a message when succeeding" do
      @str._run!
      expect(@str.messages).to eq(["Welcome to the club!"])
    end

    it "should store the user" do
      @str._run!
      expect(@str.user).to eq("Foo User")
    end

    it "should set the action as :success" do
      @str._run!
      expect(@str.result).to be(:success)
    end
  end

  describe "custom response" do
    before(:each) do
      RAS.add(:foobar) do
        def authenticate!
          custom!([521, {"foo" => "bar"}, ["BAD"]])
        end
      end
      @str = RAS[:foobar].new(env_with_params)
      @str._run!
    end

    it "should allow me to set a custom rack response" do
      expect(@str.user).to be_nil
    end

    it "should halt the strategy" do
      expect(@str).to be_halted
    end

    it "should provide access to the custom rack response" do
      expect(@str.custom_response).to eq([521, {"foo" => "bar"}, ["BAD"]])
    end

    it "should set the action as :custom" do
      @str._run!
      expect(@str.result).to eq(:custom)
    end
  end

  describe "add_message" do
    before do
      RAS.add(:foobar) do
        def authenticate!
          success!("foo")
        end
      end
    end

    let(:multiple_messages) { ['This is message one', 'This is message two'] }
    let(:single_message) { 'That is a success!' }
    let(:strategy) { RAS[:foobar].new(env_with_params) }

    it "should allow adding a single message" do
      strategy.add_message(single_message)

      expect(strategy.messages).to eql([single_message])
    end

    it "should allow adding a list of messages" do
      strategy.add_message(multiple_messages)

      expect(strategy.messages).to eql(multiple_messages)
    end

    it "should append messages" do
      strategy.add_message(multiple_messages)
      strategy.add_message(single_message)

      expect(strategy.messages).to eql(multiple_messages | [single_message])
    end
  end
end
