require 'net/https'
require 'uri'
require 'cgi'

module PayPal::SDK::Core
  module Util
    module HTTPHelper

      include Configuration
      include Logging
      include Authentication
      include Exceptions

      # Create HTTP connection based on given service name or configured end point
      def create_http_connection(uri)
        new_http(uri).tap do |http|
          if config.http_timeout
            http.open_timeout = config.http_timeout
            http.read_timeout = config.http_timeout
          end
          configure_ssl(http) if uri.scheme == "https"
        end
      end

      # New raw HTTP object
      def new_http(uri)
        if config.http_proxy
          proxy = URI.parse(config.http_proxy)
          Net::HTTP.new(uri.host, uri.port, proxy.host, proxy.port, proxy.user, proxy.password)
        else
          Net::HTTP.new(uri.host, uri.port)
        end
      end

      # Default ca file
      def default_ca_file
        File.expand_path("../../../../../data/paypal.crt", __FILE__)
      end

      # Apply ssl configuration to http object
      def configure_ssl(http)
        http.tap do |https|
          https.use_ssl = true
          https.ca_file = default_ca_file
          https.verify_mode = OpenSSL::SSL::VERIFY_PEER
          begin
            https.ssl_version = :TLSv1_2
          rescue => error
            logger.warn("WARNING: Your system does not support TLSv1.2. Per PCI Security Council mandate (https://github.com/paypal/TLS-update), you MUST update to latest security library.")
          end
          config.ssl_options.each do |key, value|
            http.send("#{key}=", value)
          end
          add_certificate(https)
        end
      end

      # Join url
      def url_join(path, action)
        path.sub(/\/?$/, "/#{action}")
      end

      # Make Http call
      # * payload - Hash(:http, :method, :uri, :body, :header)
      def http_call(payload)
        response =
          log_http_call(payload) do
            http = payload[:http] || create_http_connection(payload[:uri])
            http.start do |session|
              if [ :get, :delete, :head ].include? payload[:method]
                session.send(payload[:method], payload[:uri].request_uri, payload[:header])
              else
                session.send(payload[:method], payload[:uri].request_uri, payload[:body], payload[:header])
              end
            end
          end

        handle_response(response)
      end

      # Log Http call
      # * payload - Hash(:http, :method, :uri, :body, :header)
      def log_http_call(payload)
        logger.info {"Request[#{payload[:method]}]: #{payload[:uri].to_s}"}

        logger.debug {"Request.body=#{payload[:body]}\trequest.header=#{payload[:header]}"}

        start_time = Time.now
        response = yield
        logger.info {
          sprintf("Response[%s]: %s, Duration: %.3fs", response.code, response.message, Time.now - start_time)
        }

        logger.add(response_details_log_level(response)) {"Response.body=#{response.body}\tResponse.header=#{response.to_hash}"}

        response
      end

      # Generate header based on given header keys and properties
      # === Arguments
      # * <tt>header_keys</tt> -- List of Header keys for the properties
      # * <tt>properties</tt>  -- properties
      # === Return
      #  Hash with header as key property as value
      # === Example
      # map_header_value( { :username => "X-PAYPAL-USERNAME"}, { :username => "guest" })
      # # Return: { "X-PAYPAL-USERNAME" => "guest" }
      def map_header_value(header_keys, properties)
        header = {}
        properties.each do |key, value|
          key = header_keys[key]
          header[key] = value.to_s if key and value
        end
        header
      end

      def encode_www_form(hash)
        if defined? URI.encode_www_form
          URI.encode_www_form(hash)
        else
          hash.map{|key, value| "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}" }.join("&")
        end
      end

      # Handles response and error codes from the remote service.
      def handle_response(response)
        case response.code.to_i
          when 301, 302, 303, 307
            raise(Redirection.new(response))
          when 200...400
            response
          when 400
            raise(BadRequest.new(response))
          when 401
            raise(UnauthorizedAccess.new(response))
          when 403
            raise(ForbiddenAccess.new(response))
          when 404
            raise(ResourceNotFound.new(response))
          when 405
            raise(MethodNotAllowed.new(response))
          when 409
            raise(ResourceConflict.new(response))
          when 410
            raise(ResourceGone.new(response))
          when 422
            raise(ResourceInvalid.new(response))
          when 401...500
            raise(ClientError.new(response))
          when 500...600
            raise(ServerError.new(response))
          else
            raise(ConnectionError.new(response, "Unknown response code: #{response.code}"))
        end
      end

      private

      def response_details_log_level(response)
        if (400...600).cover?(response.code.to_i)
          Logger::WARN
        else
          Logger::DEBUG
        end
      end

    end
  end
end
