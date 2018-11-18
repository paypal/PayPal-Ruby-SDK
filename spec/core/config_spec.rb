require 'spec_helper'

describe PayPal::SDK::Core::Config do

  Config = PayPal::SDK::Core::Config

  it "load configuration file and default environment" do
    expect {
      Config.load("spec/config/paypal.yml", "test")
      expect(Config.default_environment).to eql "test"
    }.not_to raise_error
  end

  it "Set default environment" do
    begin
      backup_default_environment = Config.default_environment
      Config.default_environment = "new_env"
      expect(Config.default_environment).to eql "new_env"
    ensure
      Config.default_environment = backup_default_environment
    end
  end

  it "Set configurations" do
    begin
      backup_configurations = Config.configurations
      Config.configurations = { Config.default_environment => { :username => "direct", :password => "direct" } }
      expect(Config.config.username).to eql "direct"
      expect(Config.config.password).to eql "direct"
      expect(Config.config.signature).to be_nil
    ensure
      Config.configurations = backup_configurations
    end
  end

  it "Configure with parameters" do
    begin
      backup_configurations = Config.configurations
      Config.configurations = nil
      Config.configure( :username => "Testing" )
      expect(Config.config.username).to eql "Testing"
      expect(Config.config.app_id).to be_nil
    ensure
      Config.configurations = backup_configurations
    end
  end

  it "Configure with block" do
    begin
      backup_configurations = Config.configurations
      Config.configurations = {}
      Config.configure do |config|
        config.username = "Testing"
      end
      expect(Config.config.username).to eql "Testing"
      expect(Config.config.app_id).to be_nil
    ensure
      Config.configurations = backup_configurations
    end
  end

  it "Configure with default values" do
    begin
      backup_configurations = Config.configurations
      default_config = Config.config
      Config.configure do |config|
        config.username = "Testing"
      end
      expect(Config.config.username).to eql "Testing"
      expect(Config.config.app_id).not_to be_nil
      expect(Config.config.app_id).to eql default_config.app_id
    ensure
      Config.configurations = backup_configurations
    end
  end

  it "validate configuration" do
    config = Config.new( :username => "XYZ")
    expect {
      config.required!(:username)
    }.not_to raise_error
    expect {
      config.required!(:password)
    }.to raise_error "Required configuration(password)"
    expect {
      config.required!(:username, :password)
    }.to raise_error "Required configuration(password)"
    expect {
      config.required!(:password, :signature)
    }.to raise_error "Required configuration(password, signature)"
  end

  it "return default environment configuration" do
    expect(Config.config).to be_a Config
  end

  it "return configuration based on environment" do
    expect(Config.config(:development)).to be_a Config
  end

  it "override default configuration" do
    override_configuration = { :username => "test.example.com", :app_id => "test"}
    config = Config.config(override_configuration)

    expect(config.username).to eql(override_configuration[:username])
    expect(config.app_id).to eql(override_configuration[:app_id])
  end

  it "get cached config" do
    expect(Config.config(:test)).to eql Config.config(:test)
    expect(Config.config(:test)).not_to eql Config.config(:development)
  end

  it "should raise error on invalid environment" do
    expect {
      Config.config(:invalid_env)
    }.to raise_error "Configuration[invalid_env] NotFound"
  end

  it "set logger" do
    require 'logger'
    my_logger = Logger.new(STDERR)
    Config.logger = my_logger
    expect(Config.logger).to eql my_logger
  end

  it "Access PayPal::SDK methods" do
    expect(PayPal::SDK.configure).to eql PayPal::SDK::Core::Config.config
    expect(PayPal::SDK.logger).to eql PayPal::SDK::Core::Config.logger
    PayPal::SDK.logger = PayPal::SDK.logger
    expect(PayPal::SDK.logger).to eql PayPal::SDK::Core::Config.logger
  end

  describe "include Configuration" do
    class TestConfig
      include PayPal::SDK::Core::Configuration
    end

    it "Get default configuration" do
      test_object = TestConfig.new
      expect(test_object.config).to be_a Config
    end

    it "Change environment" do
      test_object = TestConfig.new
      test_object.set_config("test")
      expect(test_object.config).to eql Config.config("test")
      expect(test_object.config).not_to eql Config.config("development")
    end

    it "Override environment configuration" do
      test_object = TestConfig.new
      test_object.set_config("test", :username => "test")
      expect(test_object.config).not_to eql Config.config("test")
    end

    it "Override default/current configuration" do
      test_object = TestConfig.new
      test_object.set_config( :username => "test")
      expect(test_object.config.username).to eql "test"
      test_object.set_config( :password => "test")
      expect(test_object.config.password).to eql "test"
      expect(test_object.config.username).to eql "test"
    end

    it "Append ssl_options" do
      test_object = TestConfig.new
      test_object.set_config( :ssl_options => { :ca_file => "test_path" } )
      expect(test_object.config.ssl_options[:ca_file]).to eql "test_path"
      test_object.set_config( :ssl_options => { :verify_mode => 1 } )
      expect(test_object.config.ssl_options[:verify_mode]).to eql 1
      expect(test_object.config.ssl_options[:ca_file]).to eql "test_path"
    end

    it "Set configuration without loading configuration File" do
      backup_configurations = Config.configurations
      begin
        Config.configurations = nil
        test_object = TestConfig.new
        expect {
          test_object.config
        }.to raise_error
        test_object.set_config( :username => "test" )
        expect(test_object.config).to be_a Config
      ensure
        Config.configurations = backup_configurations
      end
    end

  end

end
