module Warden
  module ManagerDeprecation
    # Read the default scope from Warden
    def default_scope
      warn "[DEPRECATION] Warden::Manager.default_scope is deprecated. It's now accessible in the Warden::Manager instance."
    end

    # Set the default scope for Warden.
    def default_scope=(scope)
      warn "[DEPRECATION] Warden::Manager.default_scope= is deprecated. Please set it in the Warden::Manager instance."
    end

    # Prepares the user to serialize into the session.
    # Any object that can be serialized into the session in some way can be used as a "user" object
    # Generally however complex object should not be stored in the session.
    # If possible store only a "key" of the user object that will allow you to reconstitute it.
    #
    # Example:
    #   Warden::Manager.serialize_into_session{ |user| user.id }
    #
    # Deprecation:
    #   This method was deprecated in favor of serializer in Session. You can set it while setting the middleware:
    #
    #   use Warden::Manager do |manager|
    #     manager.serializers.update(:session) do
    #       def serialize(user)
    #         user.id
    #       end
    #     end
    #   end
    #
    # :api: public
    def serialize_into_session(&block)
      warn "[DEPRECATION] serialize_into_session is deprecated. Please overwrite the serialize method in Warden::Serializers::Session."
      Warden::Serializers::Session.send :define_method, :serialize, &block
    end

    # Reconstitues the user from the session.
    # Use the results of user_session_key to reconstitue the user from the session on requests after the initial login
    #
    # Example:
    #   Warden::Manager.serialize_from_session{ |id| User.get(id) }
    #
    # Deprecation:
    #   This method was deprecated in favor of serializer in Session. You can set it while setting the middleware:
    #
    #   use Warden::Manager do |manager|
    #     manager.serializers.update(:session) do
    #       def deserialize(id)
    #         User.get(id)
    #       end
    #     end
    #   end
    #
    # :api: public
    def serialize_from_session(&block)
      warn "[DEPRECATION] serialize_from_session is deprecated. Please overwrite the deserialize method in Warden::Serializers::Session."
      Warden::Serializers::Session.send :define_method, :deserialize, &block
    end

  end
end