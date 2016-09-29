require 'erb'
require 'yaml'

module PayPal::SDK::Core

  # Include Configuration module to access configuration from any object
  # == Examples
  #   # Include in any class
  #   include Configuration
  #
  #   # Access config object and attributes
  #   config
  #   config.username
  #
  #   # Change configuration
  #   set_config(:development)
  module Configuration

    # To get default Config object.
    def config
      @config ||= Config.config
    end

    # To change the configuration to given environment or configuration
    # === Arguments
    # * <tt>env</tt> -- Environment
    # * <tt>override_configurations</tt> (Optional) -- To override the default configuration.
    # === Examples
    #   obj.set_config(api.config)
    #   obj.set_config(:http_timeout => 30)
    #   obj.set_config(:development)
    #   obj.set_config(:development, :http_timeout => 30)
    def set_config(env, override_configurations = {})
      @config =
          case env
            when Config
              env
            when Hash
              begin
                config.dup.merge!(env)
              rescue Errno::ENOENT => error
                Config.new(env)
              end
            else
              Config.config(env, override_configurations)
          end
    end

    alias_method :config=, :set_config
  end

  # Config class is used to hold the configurations.
  # == Examples
  #   # To load configurations from file
  #   Config.load('config/paypal.yml', 'development')
  #
  #   # Get configuration
  #   Config.config   # load default configuration
  #   Config.config(:development) # load development configuration
  #   Config.config(:development, :app_id => "XYZ") # Override configuration
  #
  #   # Read configuration attributes
  #   config = Config.config
  #   config.username
  #   config.endpoint
  class Config

    include Logging
    include Exceptions

    attr_accessor :username, :password, :signature, :app_id, :cert_path,
                  :token, :token_secret, :subject,
                  :http_timeout, :http_proxy,
                  :device_ipaddress, :sandbox_email_address,
                  :mode, :endpoint, :merchant_endpoint, :platform_endpoint, :ipn_endpoint,
                  :rest_endpoint, :rest_token_endpoint, :client_id, :client_secret,
                  :openid_endpoint, :openid_redirect_uri, :openid_client_id, :openid_client_secret,
                  :verbose_logging

    alias_method :end_point=, :endpoint=
    alias_method :end_point, :endpoint
    alias_method :platform_end_point=, :platform_endpoint=
    alias_method :platform_end_point, :platform_endpoint
    alias_method :merchant_end_point=, :merchant_endpoint=
    alias_method :merchant_end_point, :merchant_endpoint
    alias_method :ipn_end_point=, :ipn_endpoint=
    alias_method :ipn_end_point, :ipn_endpoint
    alias_method :rest_end_point, :rest_endpoint
    alias_method :rest_end_point=, :rest_endpoint=
    alias_method :rest_token_end_point, :rest_token_endpoint
    alias_method :rest_token_end_point=, :rest_token_endpoint=

    # Create Config object
    # === Options(Hash)
    # * <tt>username</tt>   -- Username
    # * <tt>password</tt>   -- Password
    # * <tt>signature</tt> (Optional if certificate present) -- Signature
    # * <tt>app_id</tt>     -- Application ID
    # * <tt>cert_path</tt> (Optional if signature present)  -- Certificate file path
    def initialize(options)
      merge!(options)
    end

    def logfile=(filename)
      logger.warn '`logfile=` is deprecated, Please use `PayPal::SDK::Core::Config.logger = Logger.new(STDERR)`'
    end

    def redirect_url=(redirect_url)
      logger.warn '`redirect_url=` is deprecated.'
    end

    def dev_central_url=(dev_central_url)
      logger.warn '`dev_central_url=` is deprecated.'
    end

    def ssl_options
      @ssl_options ||= {}.freeze
    end

    def ssl_options=(options)
      options = Hash[options.map { |key, value| [key.to_sym, value] }]
      @ssl_options = ssl_options.merge(options).freeze
    end

    def ca_file=(ca_file)
      logger.warn '`ca_file=` is deprecated, Please configure `ca_file=` under `ssl_options`'
      self.ssl_options = {:ca_file => ca_file}
    end

    def http_verify_mode=(verify_mode)
      logger.warn '`http_verify_mode=` is deprecated, Please configure `verify_mode=` under `ssl_options`'
      self.ssl_options = {:verify_mode => verify_mode}
    end

    # Override configurations
    def merge!(options)
      options.each do |key, value|
        send("#{key}=", value)
      end
      self
    end

    # Validate required configuration
    def required!(*names)
      names = names.select { |name| send(name).nil? }
      raise MissingConfig.new("Required configuration(#{names.join(", ")})") if names.any?
    end

    class << self

      @@config_cache = {}

      # Load configurations from file
      # === Arguments
      # * <tt>file_name</tt>             -- Configuration file path
      # * <tt>default_environment</tt> (Optional)    -- default environment configuration to load
      # === Example
      #   Config.load('config/paypal.yml', 'development')
      def load(file_name, default_env = default_environment)
        @@config_cache = {}
        @@configurations = read_configurations(file_name)
        @@default_environment = default_env
        config
      end

      # Get default environment name
      def default_environment
        @@default_environment ||= ENV['PAYPAL_ENV'] || ENV['RACK_ENV'] || ENV['RAILS_ENV'] || "development"
      end

      # Set default environment
      def default_environment=(env)
        @@default_environment = env.to_s
      end

      def configure(options = {}, &block)
        begin
          self.config.merge!(options)
        rescue Errno::ENOENT
          self.configurations = {default_environment => options}
        end
        block.call(self.config) if block
        self.config
      end

      alias_method :set_config, :configure

      # Create or Load Config object based on given environment and configurations.
      # === Attributes
      # * <tt>env</tt> (Optional) -- Environment name
      # * <tt>override_configuration</tt> (Optional) -- Override the configuration given in file.
      # === Example
      #   Config.config
      #   Config.config(:development)
      #   Config.config(:development, { :app_id => "XYZ" })
      def config(env = default_environment, override_configuration = {})
        if env.is_a? Hash
          override_configuration = env
          env = default_environment
        end
        if override_configuration.nil? or override_configuration.empty?
          default_config(env)
        else
          default_config(env).dup.merge!(override_configuration)
        end
      end

      def default_config(env = nil)
        env = (env || default_environment).to_s
        if configurations[env]
          @@config_cache[env] ||= new(configurations[env])
        else
          raise Exceptions::MissingConfig.new("Configuration[#{env}] NotFound")
        end
      end

      # Set logger
      def logger=(logger)
        Logging.logger = logger
      end

      # Get logger
      def logger
        if @@configurations[:mode] == 'live' and Logging.logger.level == Logger::DEBUG
          Logging.logger.warn "DEBUG log level not allowed in live mode for security of confidential information. Changing log level to INFO..."
          Logging.logger.level = Logger::INFO
        end
        Logging.logger
      end

      # Get raw configurations in Hash format.
      def configurations
        @@configurations ||= read_configurations
      end

      # Set configuration
      def configurations=(configs)
        @@config_cache = {}
        @@configurations = configs && Hash[configs.map { |k, v| [k.to_s, v] }]
      end

      private
      # Read configurations from the given file name
      # === Arguments
      # * <tt>file_name</tt> (Optional) -- Configuration file path
      def read_configurations(file_name = "config/paypal.yml")
        erb = ERB.new(File.read(file_name))
        erb.filename = file_name
        YAML.load(erb.result)
      end

    end
  end
end
