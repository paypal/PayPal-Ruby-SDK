require 'paypal-sdk-core'

module PayPal
  module SDK
    module REST
      autoload :VERSION, "paypal-sdk/rest/version"
      autoload :DataTypes, "paypal-sdk/rest/data_types"
      autoload :API, "paypal-sdk/rest/api"
      autoload :RequestDataType, "paypal-sdk/rest/request_data_type"
      autoload :SetAPI, "paypal-sdk/rest/set_api"
      autoload :GetAPI, "paypal-sdk/rest/get_api"
      autoload :ErrorHash, "paypal-sdk/rest/error_hash"

      include DataTypes
      include Core::Exceptions

      module ClassMethods
        def method_missing(name, *args)
          RequestDataType.send(name, *args)
        end
      end

      class << self
        def new(*args)
          API.new(*args)
        end

        include ClassMethods

        def included(klass)
          if klass.is_a? Module
            klass.extend(ClassMethods)
          end
        end
      end

    end
  end
end
