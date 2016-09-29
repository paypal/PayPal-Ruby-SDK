module PayPal
  module SDK
    module Core
      module Credential
        autoload :Base, "paypal-sdk/core/credential/base"
        autoload :Certificate, "paypal-sdk/core/credential/certificate"
        autoload :Signature, "paypal-sdk/core/credential/signature"

        module ThirdParty
          autoload :Token, "paypal-sdk/core/credential/third_party/token"
          autoload :Subject, "paypal-sdk/core/credential/third_party/subject"
        end
      end
    end
  end
end
