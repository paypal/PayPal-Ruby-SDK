# This class was generated on Tue, 10 Apr 2018 20:34:52 UTC by version 0.1.0-dev+85d661 of Braintree SDK Generator
# order_get_request.rb
# @version 0.1.0-dev+85d661
# @type request
# @data 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
# DO NOT EDIT
require 'cgi'

module PayPal
  module V1
    module Payments

      #
      # Shows details for an order, by ID.
      #
      class OrderGetRequest
        attr_accessor :path, :body, :headers, :verb

        def initialize(order_id)
          @headers = {}
          @body = nil
          @verb = "GET"
          @path = "/v1/payments/orders/{order_id}?"

          @path = @path.gsub("{order_id}", CGI::escape(order_id.to_s))
          @headers["Content-Type"] = "application/json"
        end
      end
    end
  end
end
