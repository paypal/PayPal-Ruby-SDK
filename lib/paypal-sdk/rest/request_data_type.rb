module PayPal
  module SDK
    module REST
      module RequestDataType
        # Get a local API object or Class level API object
        def api
          @api || self.class.api
        end

        # Convert Hash object to ErrorHash object
        def error=(hash)
          @error =
              if hash.is_a? Hash
                ErrorHash.convert(hash)
              else
                hash
              end
        end

        class << self
          # Global API object
          # === Example
          #   RequestDataType.api
          def api
            @api ||= API.new
          end

          # Setter for RequestDataType.api
          # === Example
          #   RequestDataType.set_config(..)
          include SetAPI

          # Configure depended module, when RequestDataType is include.
          # === Example
          #   class Payment < DataTypes
          #     include RequestDataType
          #   end
          #   Payment.set_config(..)
          #   payment.set_config(..)
          #   Payment.api
          #   payment.api
          def included(klass)
            klass.class_eval do
              extend GetAPI
              extend SetAPI
              include SetAPI
            end
          end
        end
      end
    end
  end
end
