module PayPal::SDK::Core
  module Credential
    module ThirdParty
      class Subject

        attr_accessor :subject, :credential

        # Initialize configuration
        # === Arguments
        # * <tt>credential</tt> -- Credential object
        # * <tt>config</tt> -- Configuration object
        def initialize(credential, config)
          @credential = credential
          @subject = config.subject
        end

        # Return properties for authentication.
        def properties
          credential.properties.merge(:subject => subject)
        end

      end
    end
  end
end
