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
  end
end