require File.dirname(__FILE__) + '/../spec_helper'

describe Rack::Auth::Strategies do
  it "should let me add a strategy via a block" do
    Rack::Auth::Strategies.add(:strategy1) do
      def authenticate!
        success("foo")
      end
    end
    Rack::Auth::Strategies[:strategy1].ancestors.should include(Rack::Auth::Strategies::Base)
  end
  
  it "should raise an error if I add a strategy via a block, that does not have an autheniticate! method" do
    lambda do
      Rack::Auth::Strategies.add(:strategy2) do
      end
    end.should raise_error
  end
  
  it "should allow me to get access to a particular middleware" do
    Rack::Auth::Strategies.add(:strategy3) do
      def authenticate!; end
    end
    strategy = Rack::Auth::Strategies[:strategy3]
    strategy.should_not be_nil
    strategy.ancestors.should include(Rack::Auth::Strategies::Base)
  end
  
  it "should allow me to add a strategy with the required methods" do
    class MyStrategy
      def initialize(env, config = {}); end
      def _run!; end
      def status; end
      def headers; end
      def user; end
    end
    lambda do
      Rack::Auth::Strategies.add(:strategy4, MyStrategy)
    end.should_not raise_error
  end
  
  it "should not allow a strategy that does not have a call(env) and initialize(app, config={}) method" do
    class MyOtherStrategy
    end
    lambda do
      Rack::Auth::Strategies.add(:strategy5, MyOtherStrategy)
    end.should raise_error
  end

  it "should allow me to inherit from a class when providing a block and class" do
    class MyStrategy
      def call
        request.env['auth.spec.strategies'] ||= []
        request.env['auth.spec.strategies'] << :inherited
      end
    end

    Rack::Auth::Strategies.add(:foo, MyStrategy) do
      def authenticate!
        self.call
      end
    end

    Rack::Auth::Strategies[:foo].ancestors.should include(MyStrategy)

  end
  
  it "should allow me to clear the strategies" do
    Rack::Auth::Strategies.add(:foobar) do
      def authenticate!
        :foo
      end
    end
    Rack::Auth::Strategies[:foobar].should_not be_nil
    Rack::Auth::Strategies.clear!
    Rack::Auth::Strategies[:foobar].should be_nil
  end
end
