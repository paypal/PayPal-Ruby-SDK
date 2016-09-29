module PayPal::SDK
  module Core
    module OpenIDConnect
      autoload :API, "paypal-sdk/core/openid_connect/api"
      autoload :SetAPI, "paypal-sdk/core/openid_connect/set_api"
      autoload :GetAPI, "paypal-sdk/core/openid_connect/get_api"
      autoload :RequestDataType, "paypal-sdk/core/openid_connect/request_data_type"
      autoload :DataTypes, "paypal-sdk/core/openid_connect/data_types"

      include DataTypes

      class << self
        def api
          RequestDataType.api
        end

        def set_config(*args)
          RequestDataType.set_config(*args)
        end

        alias_method :config=, :set_config

        AUTHORIZATION_URL = "paypal.com/signin/authorize"
        ENDSESSION_URL = "paypal.com/webapps/auth/protocol/openidconnect/v1/endsession"
        DEFAULT_SCOPE = "openid"

        def authorize_url(params = {})
          uri = URI(url_for_mode(AUTHORIZATION_URL))
          uri.query = api.encode_www_form({
                                              :response_type => "code",
                                              :scope => DEFAULT_SCOPE,
                                              :client_id => RequestDataType.client_id,
                                              :redirect_uri => api.config.openid_redirect_uri
                                          }.merge(params))
          uri.to_s
        end

        def logout_url(params = {})
          uri = URI(url_for_mode(ENDSESSION_URL))
          uri.query = api.encode_www_form({
                                              :logout => "true",
                                              :redirect_uri => api.config.openid_redirect_uri
                                          }.merge(params))
          uri.to_s
        end

        private

        def url_for_mode(url)
          "https://www.#{"sandbox." if api.api_mode == :sandbox}#{url}"
        end
      end

      module DataTypes
        class Tokeninfo < Base
          include RequestDataType
          PATH = "v1/identity/openidconnect/tokenservice"
          FP_PATH = "v1/oauth2/token"

          class << self

            def basic_auth_header(options)
              credentials = options[:client_id].to_s + ":" + options[:client_secret].to_s
              encoded = Base64.encode64(credentials.force_encoding('UTF-8')).gsub!(/\n/, "")
              "Basic #{encoded}"
            end

            def create_from_authorization_code(options, http_header = {})
              options = {:code => options} if options.is_a? String
              options = options.merge(:grant_type => "authorization_code")
              Tokeninfo.new(api.post(PATH, with_credentials(options), http_header))
            end

            alias_method :create, :create_from_authorization_code

            def create_from_refresh_token(options, http_header = {})
              options = {:refresh_token => options} if options.is_a? String
              options = options.merge(:grant_type => "refresh_token")
              http_header = http_header.merge({"Content-Type" => "application/x-www-form-urlencoded", "Authorization" => basic_auth_header(with_credentials(options))})
              Tokeninfo.new(api.post(PATH, options, http_header))
            end

            alias_method :refresh, :create_from_refresh_token

            def create_from_future_payment_auth_code(options, http_header = {})
              options = {:code => options} if options.is_a? String
              options = options.merge({:grant_type => "authorization_code", :response_type => "token", :redirect_uri => "urn:ietf:wg:oauth:2.0:oob"})
              http_header = http_header.merge({"Content-Type" => "application/x-www-form-urlencoded", "Authorization" => basic_auth_header(with_credentials(options))})
              Tokeninfo.new(api.post(FP_PATH, options, http_header))
            end

            alias_method :token_hash, :create_from_future_payment_auth_code
            alias_method :create_fp, :create_from_future_payment_auth_code

            def with_credentials(options = {})
              options = options.dup
              [:client_id, :client_secret].each do |key|
                options[key] = self.send(key) unless options[key] or options[key.to_s]
              end
              options
            end

            def authorize_url(options = {})
              OpenIDConnect.authorize_url(options)
            end
          end

          def refresh(options = {})
            tokeninfo = self.class.refresh({
                                               :refresh_token => self.refresh_token}.merge(options))
            self.merge!(tokeninfo.to_hash)
          end

          def userinfo(options = {})
            Userinfo.get({:access_token => self.access_token}.merge(options))
          end

          def logout_url(options = {})
            OpenIDConnect.logout_url({:id_token => self.id_token}.merge(options))
          end

        end

        class Userinfo < Base
          include RequestDataType
          PATH = "v1/identity/openidconnect/userinfo"

          class << self
            def get_userinfo(options = {}, http_header = {})
              options = {:access_token => options} if options.is_a? String
              options = options.merge(:schema => "openid") unless options[:schema] or options["schema"]
              Userinfo.new(api.post(PATH, options, http_header))
            end

            alias_method :get, :get_userinfo
          end
        end
      end
    end
  end

  # Alias for the Core::OpenIDConnect constant
  OpenIDConnect = Core::OpenIDConnect
end
