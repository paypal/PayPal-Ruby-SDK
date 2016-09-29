module PayPal
  module SDK
    module Core

      autoload :VERSION, "paypal-sdk/rest/version"
      autoload :Config, "paypal-sdk/core/config"
      autoload :Configuration, "paypal-sdk/core/config"
      autoload :Logging, "paypal-sdk/core/logging"
      autoload :Authentication, "paypal-sdk/core/authentication"
      autoload :Exceptions, "paypal-sdk/core/exceptions"
      autoload :OpenIDConnect, "paypal-sdk/core/openid_connect"
      autoload :API, "paypal-sdk/core/api"
      autoload :Util, "paypal-sdk/core/util"
      autoload :Credential, "paypal-sdk/core/credential"

    end

    autoload :OpenIDConnect, "paypal-sdk/core/openid_connect"

    class << self
      def configure(options = {}, &block)
        Core::Config.configure(options, &block)
      end

      def load(*args)
        Core::Config.load(*args)
      end

      def logger
        Core::Config.logger
      end

      def logger=(log)
        Core::Config.logger = log
      end
    end
  end
end
