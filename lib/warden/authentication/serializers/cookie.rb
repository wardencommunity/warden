# encoding: utf-8
module Warden
  module Serializers
    # A cookie serializer provided by Warden. You need to implement the serialize and deserialize
    # methods in order to use it.
    class Cookie < Base
      def store(user, scope)
        response.set_cookie key_for(scope), default_options(user)
      end

      def fetch(scope)
        key = request.cookies[key_for(scope)]
        return nil unless key
        user = deserialize(key)
        delete(scope) unless user
        user
      end

      def stored?(scope)
        !!request.cookies[key_for(scope)]
      end

      def delete(scope, user=nil)
        response.delete_cookie(key_for(scope))
      end

      def default_options(user)
        { :value => serialize(user), :expires => (Time.now + 7 * 24 * 3600), :path => "/" }
      end
    end # Cookie

    Serializers.add(:cookie, Cookie)
  end # Serializers
end # Warden