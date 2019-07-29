module PayPal
  module SDK
    module Core
      module API
        module IPN

          END_POINTS = {
            :sandbox => "https://ipnpb.sandbox.paypal.com/cgi-bin/webscr",
            :live    => "https://ipnpb.paypal.com/cgi-bin/webscr"
          }
          VERIFIED   = "VERIFIED"
          INVALID    = "INVALID"

          class Message
            include Util::HTTPHelper

            attr_accessor :message

            def initialize(message, env = nil, options = {})
              @message = message
              set_config(env, options)
            end

            # Fetch end point
            def ipn_endpoint
              config.ipn_endpoint || default_ipn_endpoint
            end

            # Default IPN end point
            def default_ipn_endpoint
              endpoint = END_POINTS[(config.mode || :sandbox).to_sym] rescue nil
              endpoint || END_POINTS[:sandbox]
            end

            # Request IPN service for validating the content
            # === Return
            # return http response object
            def request
              uri  = URI(ipn_endpoint)
              query_string = "cmd=_notify-validate&#{message}"
              http_call(:method => :post, :uri => uri, :body => query_string)
            end

            # Validate the given content
            # === Return
            # return true or false
            def valid?
              request.body == VERIFIED
            end
          end

          class << self
            def valid?(*args)
              Message.new(*args).valid?
            end

            def request(*args)
              Message.new(*args).request
            end
          end

        end
      end
    end
  end
end
