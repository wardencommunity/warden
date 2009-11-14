# encoding: utf-8
module Warden
  module Serializers
    # A session serializer provided by Warden. You need to implement the serialize and deserialize
    # methods in order to use it.
    class Session < Base
      def store(user, scope)
        session[key_for(scope)] = serialize(user)
      end

      def fetch(scope)
        key = session[key_for(scope)]
        return nil unless key
        user = deserialize(key)
        delete(scope) unless user
        user
      end

      def stored?(scope)
        !!session[key_for(scope)]
      end

      def delete(scope, user=nil)
        session.delete(key_for(scope))
      end
    end # Session

    Serializers.add(:session, Session)
  end # Serializers
end # Warden