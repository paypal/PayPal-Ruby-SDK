require 'paypal-sdk/rest/version'

module PayPal::SDK::Core

  module API
    # API class provide default functionality for accessing the API web services.
    # == Example
    #   api      = API::Base.new("AdaptivePayments")
    #   response = api.request("GetPaymentOptions", "")
    class Base

      include Util::HTTPHelper

      attr_accessor :http, :uri, :service_name

      DEFAULT_API_MODE = :sandbox
      API_MODES = [:live, :sandbox]

      # Initialize API object
      # === Argument
      # * <tt>service_name</tt> -- (Optional) Service name
      # * <tt>environment</tt>  -- (Optional) Configuration environment to load
      # * <tt>options</tt> -- (Optional) Override configuration.
      # === Example
      #  new("AdaptivePayments")
      #  new("AdaptivePayments", :development)
      #  new(:wsdl_service)       # It load wsdl_service configuration
      def initialize(service_name = "", environment = nil, options = {})
        unless service_name.is_a? String
          environment, options, service_name = service_name, environment || {}, ""
        end
        @service_name = service_name
        set_config(environment, options)
      end

      def uri
        @uri ||=
            begin
              uri = URI.parse("#{service_endpoint}/#{service_name}")
              uri.path = uri.path.gsub(/\/+/, "/")
              uri
            end
      end

      def http
        @http ||= create_http_connection(uri)
      end

      # Override set_config method to create http connection on changing the configuration.
      def set_config(*args)
        @http = @uri = nil
        super
      end

      # Get configured API mode( sandbox or live)
      def api_mode
        if config.mode and API_MODES.include? config.mode.to_sym
          config.mode.to_sym
        else
          DEFAULT_API_MODE
        end
      end

      # Get service end point
      def service_endpoint
        config.endpoint
      end

      # Default Http header
      def default_http_header
        {"User-Agent" => self.class.user_agent}
      end

      # Generate HTTP request for given action and parameters
      # === Arguments
      # * <tt>http_method</tt> -- HTTP method(get/put/post/delete/patch)
      # * <tt>action</tt> -- Action to perform
      # * <tt>params</tt> -- (Optional) Parameters for the action
      # * <tt>initheader</tt> -- (Optional) HTTP header
      def api_call(payload)
        payload[:header] = default_http_header.merge(payload[:header])
        payload[:uri] ||= uri.dup
        payload[:http] ||= http.dup
        payload[:uri].query = encode_www_form(payload[:query]) if payload[:query] and payload[:query].any?
        format_request(payload)
        payload[:response] = http_call(payload)
        format_response(payload)
        payload[:data]
      end

      # Generate HTTP request for given action and parameters
      # === Arguments
      # * <tt>action</tt> -- Action to perform
      # * <tt>params</tt> -- (Optional) Parameters for the action
      # * <tt>initheader</tt> -- (Optional) HTTP header
      def post(action, params = {}, header = {}, query = {})
        action, params, header = "", action, params if action.is_a? Hash
        api_call(:method => :post, :action => action, :query => query, :params => params, :header => header)
      end

      alias_method :request, :post

      def get(action, params = {}, header = {})
        action, params, header = "", action, params if action.is_a? Hash
        api_call(:method => :get, :action => action, :query => params, :params => nil, :header => header)
      end

      def patch(action, params = {}, header = {})
        action, params, header = "", action, params if action.is_a? Hash
        api_call(:method => :patch, :action => action, :params => params, :header => header)
      end

      def put(action, params = {}, header = {})
        action, params, header = "", action, params if action.is_a? Hash
        api_call(:method => :put, :action => action, :params => params, :header => header)
      end

      def delete(action, params = {}, header = {})
        action, params, header = "", action, params if action.is_a? Hash
        api_call(:method => :delete, :action => action, :params => params, :header => header)
      end

      # Format Request data. It will be override by child class
      # == Arguments
      # * <tt>action</tt> -- Request action
      # * <tt>params</tt> -- Request parameters
      # == Return
      # * <tt>path</tt>   -- Formated request uri object
      # * <tt>params</tt> -- Formated request Parameters
      # * <tt>header</tt> -- HTTP Header
      def format_request(payload)
        payload[:uri].path = url_join(payload[:uri].path, payload[:action])
        payload[:body] = payload[:params].to_s
        payload
      end

      # Format Response object. It will be override by child class
      # == Argument
      # * <tt>action</tt> -- Request action
      # * <tt>response</tt> -- HTTP response object
      def format_response(payload)
        payload[:data] = payload[:response].body
        payload
      end

      # Format Error object. It will be override by child class.
      # == Arguments
      # * <tt>exception</tt> -- Exception object.
      # * <tt>message</tt> -- Readable error message.
      def format_error(exception, message)
        raise exception
      end

      class << self
        def sdk_library_details
          @library_details ||= "paypal-sdk-core #{PayPal::SDK::REST::VERSION}; ruby #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}-#{RUBY_PLATFORM}"
          begin
            @library_details << ";#{OpenSSL::OPENSSL_LIBRARY_VERSION}"
          rescue NameError
            @library_details << ";OpenSSL #{OpenSSL::OPENSSL_VERSION}"
          end
        end

        def user_agent
          @user_agent ||= "PayPalSDK/rest-sdk-ruby #{PayPal::SDK::REST::VERSION} (#{sdk_library_details})"
        end
      end
    end
  end
end
