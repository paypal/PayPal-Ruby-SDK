require 'json'
require 'pp'

module PayPal::SDK::Core
  module Exceptions
    class ConnectionError < StandardError # :nodoc:
      attr_reader :response

      def initialize(response, message = nil)
        @response = response
        @message = message
      end

      def to_s
        begin
          response_body = JSON.parse(response.body)
          debug_id = response["paypal-debug-id"]
          debug_id = response["correlation-id"] if debug_id.to_s == ''
          debug_id = response_body["debug_id"] if debug_id.to_s == ''
        rescue
        end
        message = "Failed."
        message << "  Response code = #{response.code}." if response.respond_to?(:code)
        message << "  Response message = #{response.message}." if response.respond_to?(:message)
        message << "  Response debug ID = #{debug_id}." if debug_id
        message
      end
    end

    # Raised when a Timeout::Error occurs.
    class TimeoutError < ConnectionError
      def initialize(message)
        @message = message
      end

      def to_s;
        @message;
      end
    end

    # Raised when a OpenSSL::SSL::SSLError occurs.
    class SSLError < ConnectionError
      def initialize(message)
        @message = message
      end

      def to_s;
        @message;
      end
    end

    # 3xx Redirection
    class Redirection < ConnectionError # :nodoc:
      def to_s
        response['Location'] ? "#{super} => #{response['Location']}" : super
      end
    end

    class MissingParam < ArgumentError # :nodoc:
    end

    class MissingConfig < StandardError # :nodoc:
    end

    # 4xx Client Error
    class ClientError < ConnectionError # :nodoc:
    end

    # 400 Bad Request
    class BadRequest < ClientError # :nodoc:
    end

    # 401 Unauthorized
    class UnauthorizedAccess < ClientError # :nodoc:
    end

    # 403 Forbidden
    class ForbiddenAccess < ClientError # :nodoc:
    end

    # 404 Not Found
    class ResourceNotFound < ClientError # :nodoc:
    end

    # 409 Conflict
    class ResourceConflict < ClientError # :nodoc:
    end

    # 410 Gone
    class ResourceGone < ClientError # :nodoc:
    end

    # 5xx Server Error
    class ServerError < ConnectionError # :nodoc:
    end

    # 405 Method Not Allowed
    class MethodNotAllowed < ClientError # :nodoc:
      def allowed_methods
        @response['Allow'].split(',').map { |verb| verb.strip.downcase.to_sym }
      end
    end

    # API error: returned as 200 + "error" key in response.
    class UnsuccessfulApiCall < RuntimeError
      attr_reader :api_error

      def initialize(api_error)
        super(api_error['message'])
        @api_error = api_error
      end
    end
  end
end
