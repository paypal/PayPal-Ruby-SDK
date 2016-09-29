require 'uri'
require 'cgi'
require 'openssl'
require 'base64'

module PayPal::SDK::Core
  module Util
    class OauthSignature
      attr_accessor :username, :password, :token, :token_secret, :url, :timestamp

      def initialize(username, password, token, token_secret, url, timestamp = nil)
        @username = username
        @password = password
        @token = token
        @token_secret = token_secret
        @url = url
        @timestamp = timestamp || Time.now.to_i.to_s
      end

      def authorization_string
        signature = oauth_signature
        "token=#{token},signature=#{signature},timestamp=#{timestamp}"
      end

      def oauth_signature
        key = [
            paypal_encode(password),
            paypal_encode(token_secret),
        ].join("&").gsub(/%[0-9A-F][0-9A-F]/, &:downcase)

        digest = OpenSSL::HMAC.digest('sha1', key, base_string)
        Base64.encode64(digest).chomp
      end

      def base_string
        params = {
            "oauth_consumer_key" => username,
            "oauth_version" => "1.0",
            "oauth_signature_method" => "HMAC-SHA1",
            "oauth_token" => token,
            "oauth_timestamp" => timestamp,
        }
        sorted_query_string = params.sort.map { |v| v.join("=") }.join("&")

        base = [
            "POST",
            paypal_encode(url),
            paypal_encode(sorted_query_string)
        ].join("&")
        base = base.gsub(/%[0-9A-F][0-9A-F]/, &:downcase)
      end

      # The PayPalURLEncoder java class percent encodes everything other than 'a-zA-Z0-9 _'.
      # Then it converts ' ' to '+'.
      # Ruby's CGI.encode takes care of the ' ' and '*' to satisfy PayPal
      # (but beware, URI.encode percent encodes spaces, and does nothing with '*').
      # Finally, CGI.encode does not encode '.-', which we need to do here.
      def paypal_encode str
        CGI.escape(str.to_s).gsub('.', '%2E').gsub('-', '%2D')
      end
    end
  end
end

