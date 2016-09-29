module PayPal::SDK::Core
  module Credential
    class Signature < Base

      attr_accessor :signature

      # Initialize configuration
      # === Argument
      # * <tt>config</tt> -- Configuration object
      def initialize(config)
        super
        self.signature = config.signature
      end

      # Return properties for authentication
      def properties
        super.merge({:signature => signature})
      end

    end
  end
end
