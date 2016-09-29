module PayPal::SDK::Core
  module Credential

    # Certificate class for SSL Certificate authentication
    class Certificate < Base

      attr_reader :cert_path

      def initialize(config)
        super
        @cert_path = config.cert_path
      end

      # Return SSL certificate
      def cert
        @cert ||= OpenSSL::X509::Certificate.new(cert_content)
      end

      # Return SSL certificate key
      def key
        @key = OpenSSL::PKey::RSA.new(cert_content)
      end

      private
      # Return certificate content from the configured file.
      def cert_content
        @cert_content ||= File.read(cert_path)
      end

    end
  end
end
