module PayPal::SDK::Core
  module Credential

    # Base credential Class for authentication
    class Base
      attr_accessor :username, :password, :app_id, :device_ipaddress, :sandbox_email_address

      # Initialize authentication configurations
      # === Arguments
      #  * <tt>config</tt> -- Configuration object
      def initialize(config)
        self.username = config.username
        self.password = config.password
        self.app_id = config.app_id
        self.device_ipaddress = config.device_ipaddress
        self.sandbox_email_address = config.sandbox_email_address
      end

      # Return credential properties
      def properties
        {:username => username, :password => password, :app_id => app_id,
         :device_ipaddress => device_ipaddress, :sandbox_email_address => sandbox_email_address}
      end

    end
  end
end
