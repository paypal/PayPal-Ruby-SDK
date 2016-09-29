module PayPal::SDK
  module Core
    module OpenIDConnect
      module SetAPI
        # Set new api
        # === Examples
        #   payment.set_config(:development)
        #   payment.set_config(:client_id => "XYZ", :client_secret => "SECRET")
        #   payment.set_config
        #   payment.api = API.new(:development)
        def set_config(*args)
          if args[0].is_a?(API)
            @api = args[0]
          else
            @api ||= API.new({})
            @api.set_config(*args) # Just override the configuration and Not
            @api
          end
        end

        alias_method :config=, :set_config
        alias_method :set_api, :set_config
        alias_method :api=, :set_config

        # Override client id
        def client_id=(client_id)
          set_config(:client_id => client_id)
        end

        # Override client secret
        def client_secret=(client_secret)
          set_config(:client_secret => client_secret)
        end
      end
    end
  end
end
