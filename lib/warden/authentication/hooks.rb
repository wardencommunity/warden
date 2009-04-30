module Warden
  class Manager
    
    class << self
      # A callback hook set to run every time after a user is set.
      # This will happen the first time the user is either authenticated, accessed or manually set
      # during a request.  You can supply as many hooks as you like, and they will be run in order of decleration
      # 
      # Parameters: 
      # <block> A block where you can set arbitrary logic to run every time a user is set
      #   Block Parameters: |user, auth, opts|
      #     user - The user object that is being set
      #     auth - The raw authentication proxy object.  
      #     opts - any options passed into the set_user call includeing :scope
      # 
      # Example:
      #   Warden::Manager.after_set_user do |user,auth,opts|
      #     scope = opts[:scope]
      #     if auth.session["#{scope}.last_access"].to_i > (Time.now - 5.minutes)
      #       auth.logout(scope)
      #       throw(:warden, :scope => scope, :reason => "Times Up")
      #     end
      #     auth.session["#{scope}.last_access"] = Time.now
      #   end
      #
      # :api: public
      def after_set_user(&block)
        raise BlockNotGiven unless block_given?
        _after_set_user << block
      end
      
      # Provides access to the array of after_set_user blocks to run
      # :api: private
      def _after_set_user # :nodoc:
        @_after_set_user ||= []
      end
      
      # A callback hook set to run after the first authentiation of a session.  
      # This will only happenwhen the session is first authenticated
      # 
      # Parameters:
      # <block> A block to contain logic for the callback
      #   Block Parameters: |user, auth, opts|
      #     user - The user object that is being set
      #     auth - The raw authentication proxy object.  
      #     opts - any options passed into the authenticate call includeing :scope
      # 
      # Example:
      #
      #   Warden::Manager.after_authentication do |user, auth, opts|
      #     throw(:warden, opts) unless user.active?
      #   end
      #
      # :api: public
      def after_authentication(&block)
        raise BlockNotGiven unless block_given?
        _after_authentication << block
      end
      
      # Provides access to the array of after_authentication blocks
      # :api: private
      def _after_authentication
        @_after_authentication ||= []
      end
      
      # A callback that runs just prior to the failur application being called.  
      # This callback occurs after PATH_INFO has been modified for the failure (default /unauthenticated)
      # In this callback you can mutate the environment as required by the failure application
      # If a Rails controller were used for the failure_app for example, you would need to set request[:params][:action] = :unauthenticated
      # 
      # Parameters:
      # <block> A block to contain logic for the callback
      #   Block Parameters: |user, auth, opts|
      #     env - The rack env hash
      #     opts - any options passed into the authenticate call includeing :scope
      #
      # Example:
      #   Warden::Manager.before_failure do |env, opts|
      #     params = Rack::Request.new(env).params
      #     params[:action] = :unauthenticated
      #     params[:warden_failure] = opts
      #   end
      # 
      # :api: public
      def before_failure(&block)
        _before_failure << block
      end
      
      # Provides access to the callback array for before_failure
      # :api: private
      def _before_failure
        @_before_failure ||= []
      end
      
      # A callback that runs just after to the failur application being called.  
      # This callback is primarily included for Rails 2.3 since Rails 2.3 controllers are not pure Rack Applications
      # Return whatever you want to be returned for the actual rack response array
      # 
      # Parameters:
      # <block> A block to contain logic for the callback
      #   Block Parameters: |user, auth, opts|
      #     result - The result of the rack application
      #     opts - any options passed into the authenticate call includeing :scope
      #
      # Example:
      #   # Rails 2.3 after_failure
      #   Warden::Manager.after_failure do |result|
      #    result.to_a
      #   end
      # 
      # :api: public
      def after_failure(&block)
        _after_failure << block
      end
      
      # Provides access to the callback array for after_failure
      # :api: private
      def _after_failure
        @_after_failure ||= []
      end
      
    end
    
  end # Manager
end # Warden