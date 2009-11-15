# encoding: utf-8
module Warden
  module Serializers
    # A serializer is a place where you put the logic to serializing and deserializing an user. All serializers
    # inherits from Warden::Serializers::Base.
    #
    # The Warden::Serializers.add method is a simple way to provide custom serializers. In order to do so,
    # you _must_ declare @store@, @fetch@, @delete@ and @stored?@ methods.
    # 
    # The parameters for Warden::Serializers.add method is: 
    #   <label: Symbol> The label is the name given to a serializer. Use the label to refer to the serializer when authenticating
    #   <serializer: Class|nil> The optional serializer argument if set _must_ be a class that inherits from Warden::Serializers::Base
    #   <block> The block acts as a convinient way to declare your serializer.  Inside is the class definition of a serializer.
    #
    # Check Session and Cookie serializers for more information.
    #
    class Base
      attr_accessor :env
      include ::Warden::Mixins::Common

      def initialize(env)
        @env = env
      end

      def key_for(scope)
        "warden.user.#{scope}.key"
      end

      def serialize(user)
        user
      end

      def deserialize(key)
        key
      end
    end # Base
  end # Serializers
end # Warden