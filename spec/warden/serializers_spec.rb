require File.dirname(__FILE__) + '/../spec_helper'

describe Warden::Serializers do
  it "should let me add a serializer via a block" do
    Warden::Serializers.add(:serializer1) do
      def fetch; end
      def store; end
      def stored?; end
      def delete; end
    end
    Warden::Serializers[:serializer1].ancestors.should include(Warden::Serializers::Base)
  end
  
  it "should raise an error if I add a serializer via a block, that does not have an autheniticate! method" do
    lambda do
      Warden::Serializers.add(:serializer2) do
      end
    end.should raise_error
  end
  
  it "should allow me to get access to a particular serializer" do
    Warden::Serializers.add(:serializer3) do
      def fetch; end
      def store; end
      def stored?; end
      def delete; end
    end
    serializer = Warden::Serializers[:serializer3]
    serializer.should_not be_nil
    serializer.ancestors.should include(Warden::Serializers::Base)
  end
  
  it "should allow me to add a serializer with the required methods" do
    class MySerializer < Warden::Serializers::Base
      def fetch; end
      def store; end
      def stored?; end
      def delete; end
    end
    lambda do
      Warden::Serializers.add(:serializer4, MySerializer)
    end.should_not raise_error
  end
  
  it "should not allow a serializer that does not have any required method" do
    class MyOtherSerializer
    end
    lambda do
      Warden::Serializers.add(:serializer5, MyOtherSerializer)
    end.should raise_error
  end

  it "should allow me to change a class when providing a block and class" do
    class MySerializer < Warden::Serializers::Base
    end

    Warden::Serializers.add(:foo, MySerializer) do
      def fetch; end
      def store; end
      def stored?; end
      def delete; end
    end

    Warden::Serializers[:foo].ancestors.should include(MySerializer)
  end

  it "should allow me to update a previously given serializer" do
    class MySerializer < Warden::Serializers::Base
      def fetch; end
      def store; end
      def stored?; end
      def delete; end
    end

    Warden::Serializers.add(:serializer6, MySerializer)

    new_module = Module.new
    Warden::Serializers.update(:serializer6) do
      include new_module
    end

    Warden::Serializers[:serializer6].ancestors.should include(new_module)
  end

  it "should allow me to clear the Serializers" do
    old_serializers = Warden::Serializers._serializers.dup

    begin
      Warden::Serializers.add(:foobar) do
        def fetch; end
        def store; end
        def stored?; end
        def delete; end
      end
      Warden::Serializers[:foobar].should_not be_nil
      Warden::Serializers.clear!
      Warden::Serializers[:foobar].should be_nil
    else
      Warden::Serializers._serializers.replace(old_serializers)
    end
  end
end
