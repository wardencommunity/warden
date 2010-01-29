# encoding: utf-8
module Warden
  module ManagerDeprecation
    class Dummy
      def update(type, &block)
        if type == :session
          warn "[DEPRECATION] warden.serializers.update(:session) is deprecated. " <<
               "Please use Warden::Manager.serialize_from_session and Warden::Manager.serialize_into_session"
          Warden::SessionSerializer.class_eval(&block)
        else
          method_missing(update)
        end
      end

      def method_missing(method, *args)
        warn "[DEPRECATION] warden.serializers.#{method} is deprecated."
        nil
      end
    end

    # Read the default scope from Warden
    def default_scope
      warn "[DEPRECATION] Warden::Manager.default_scope is deprecated. It's now accessible in the Warden::Manager instance."
    end

    # Set the default scope for Warden.
    def default_scope=(scope)
      warn "[DEPRECATION] Warden::Manager.default_scope= is deprecated. Please set it in the Warden::Manager instance."
    end

    def serializers
      warn "[DEPRECATION] warden.serializers is deprecated since Warden::Serializers were merged into Warden::Strategies."
      Dummy.new
    end
  end
end