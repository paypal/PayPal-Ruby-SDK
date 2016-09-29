module PayPal
  module SDK
    module Core
      module API
        autoload :Base, "paypal-sdk/core/api/base"
        autoload :Merchant, "paypal-sdk/core/api/merchant"
        autoload :Platform, "paypal-sdk/core/api/platform"
        autoload :REST, "paypal-sdk/core/api/rest"
        autoload :IPN, "paypal-sdk/core/api/ipn"

        module DataTypes
          autoload :Base, "paypal-sdk/core/api/data_types/base"
          autoload :Enum, "paypal-sdk/core/api/data_types/enum"
          autoload :SimpleTypes, "paypal-sdk/core/api/data_types/simple_types"
          autoload :ArrayWithBlock, "paypal-sdk/core/api/data_types/array_with_block"
        end
      end
    end
  end
end
