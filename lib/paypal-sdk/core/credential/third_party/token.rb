module PayPal::SDK::Core
  module Credential
    module ThirdParty
      class Token

        attr_accessor :token, :token_secret, :credential, :url

        # Initialize Token credentials
        # === Arguments
        # * <tt>credential</tt> -- Credential Object
        # * <tt>config</tt> -- Configuration object
        # * <tt>url</tt> -- Request url
        def initialize(credential, config, url)
          @credential = credential
          @token = config.token
          @token_secret = config.token_secret
          @url = url
        end

        RemoveProperties = [:username, :password, :signature]

        # Return credential properties for authentication.
        def properties
          credential_properties = credential.properties
          credential_properties.delete_if { |k, v| RemoveProperties.include? k }
          credential_properties.merge(:authorization => oauth_authentication)
        end

        private
        # Return OAuth authentication string.
        def oauth_authentication
          Util::OauthSignature.new(credential.username, credential.password, token, token_secret, url).
              authorization_string
        end

      end
    end
  end
end
