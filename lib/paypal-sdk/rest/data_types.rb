require 'paypal-sdk-core'
require 'securerandom'
require 'multi_json'
require 'zlib'
require "base64"
require 'net/http'

module PayPal::SDK
  module REST
    module DataTypes
      class Base < Core::API::DataTypes::Base
        attr_accessor :error
        attr_writer   :header, :request_id

        def header
          @header ||= {}
        end

        def request_id
          @request_id ||= SecureRandom.uuid
        end

        def http_header
          { "PayPal-Request-Id" => request_id.to_s }.merge(header)
        end

        def success?
          @error.nil?
        end

        def merge!(values)
          @error = nil
          super
        end

        def raise_error!
          raise Core::Exceptions::UnsuccessfulApiCall, error if error
        end

        def self.load_members
        end

        def self.raise_on_api_error(*methods)
          methods.each do |symbol|
            define_method("#{symbol}!") {|*arg|
              raise_error! unless send(symbol, *arg)
            }
          end
        end

        class Number < Float
        end
      end

      class Payment < Base
        def self.load_members
          object_of :id, String
          object_of :intent, String
          object_of :payer, Payer
          object_of :payee, Payee
          object_of :cart, String
          array_of  :transactions, Transaction
          array_of  :failed_transactions, Error
          object_of :payment_instruction, PaymentInstruction
          object_of :state, String
          object_of :experience_profile_id, String
          object_of :note_to_payer, String
          object_of :redirect_urls, RedirectUrls
          object_of :failure_reason, String
          object_of :create_time, String
          object_of :update_time, String
          array_of  :links, Links
          object_of :note_to_payer, String
          array_of  :billing_agreement_tokens, String
          object_of :potential_payer_info, PotentialPayerInfo
          object_of :credit_financing_offered, CreditFinancingOffered
          object_of :failure_reason, String
        end

        include RequestDataType

        def create()
          path = "v1/payments/payment"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def update(patch_requests)
          patch_request_array = []
          patch_requests.each do |patch_request|
            patch_request = Patch.new(patch_request) unless patch_request.is_a? Patch
            patch_request_array << patch_request.to_hash
          end
          path = "v1/payments/payment/#{self.id}"
          response = api.patch(path, patch_request_array, http_header)
          self.merge!(response)
          success?
        end

        def execute(payment_execution)
          payment_execution = PaymentExecution.new(payment_execution) unless payment_execution.is_a? PaymentExecution
          path = "v1/payments/payment/#{self.id}/execute"
          response = api.post(path, payment_execution.to_hash, http_header)
          self.merge!(response)
          success?
        end

        raise_on_api_error :create, :update, :execute

        def approval_url(immediate = false)
          link = links.detect { |l| l.rel == 'approval_url' }
          return nil unless link
          link.href + (immediate ? '&useraction=commit' : '')
        end

        def token
          url = approval_url
          return nil unless url
          CGI.parse(URI.parse(url).query)['token'].first
        end

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/payment/#{resource_id}"
            self.new(api.get(path))
          end

          def all(options = {})
            path = "v1/payments/payment"
            PaymentHistory.new(api.get(path, options))
          end
        end
      end

      class PotentialPayerInfo < Base
        def self.load_members
          object_of :email, String
          object_of :external_remember_me_id, String
          object_of :billing_address, Address
        end

        include RequestDataType
      end

      class ProcessorResponse < Base
        def self.load_members
          object_of :response_code, String
          object_of :avs_code, String
          object_of :cvv_code, Address
          object_of :advice_code, String
          object_of :eci_submitted, String
          object_of :vpas, String
        end

        include RequestDataType
      end

      class AlternatePayment < Base
        def self.load_members
          object_of :alternate_payment_account_id, String
          object_of :external_customer_id, String
          object_of :alternate_payment_provider_id, String
        end

        include RequestDataType
      end

      class Billing < Base
        def self.load_members
          object_of :billing_agreement_id, String
          object_of :selected_installment_option, InstallmentOption
        end

        include RequestDataType
      end

      class BillingAgreementToken < Base
        def self.load_members
        end

        include RequestDataType
      end

      class CountryCode < Base
        def self.load_members
          object_of :country_code, String
        end

        include RequestDataType
      end

      class CreditFinancingOffered < Base
        def self.load_members
          object_of :total_cost, Currency
          object_of :term, Number
          object_of :monthly_payment, Currency
          object_of :total_interest, Currency
          object_of :payer_acceptance, Boolean
          object_of :cart_amount_immutable, Boolean
        end

        include RequestDataType
      end

      class ExternalFunding < Base
        def self.load_members
          object_of :reference_id, String
          object_of :code, String
          object_of :funding_account_id, String
          object_of :display_text, String
          object_of :amount, Currency
          object_of :funding_instruction, String
        end

        include RequestDataType
      end

      class PotentialPayerInfo < Base
        def self.load_members
          object_of :email, String
          object_of :external_remember_me_id, String
          object_of :billing_address, Address
        end

        include RequestDataType
      end

      class PrivateLabelCard < Base
        def self.load_members
          object_of :id, String
          object_of :card_number, String
          object_of :issuer_id, Address
          object_of :issuer_name, Address
          object_of :image_key, Address
        end

        include RequestDataType
      end

      class ProcessorResponse < Base
        def self.load_members
          object_of :response_code, String
          object_of :avs_code, String
          object_of :cvv_code, String
          object_of :advice_code, String
          object_of :eci_submitted, String
          object_of :vpas, String
        end

        include RequestDataType
      end




      class FuturePayment < Payment

        def create(correlation_id=nil)
          path = "v1/payments/payment"
          if correlation_id != nil
            header = http_header
            header = header.merge({
              "PAYPAL-CLIENT-METADATA-ID" => correlation_id})
          end
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        raise_on_api_error :create

        class << self

          def exch_token(auth_code)
            if auth_code
              PayPal::SDK::OpenIDConnect::DataTypes::Tokeninfo.token_hash(auth_code)
            else
              raise ArgumentError.new("authorization code required") if auth_code.to_s.strip.empty?
            end
          end

        end
      end

      class Payer < Base
        def self.load_members
          object_of :payment_method, String
          object_of :status, String
          object_of :account_type, String
          object_of :account_age, String
          array_of  :funding_instruments, FundingInstrument
          object_of :funding_option_id, String
          object_of :funding_option, FundingOption
          object_of :external_selected_funding_instrument_type, String
          object_of :related_funding_option, FundingOption
          object_of :payer_info, PayerInfo
          object_of :billing, Billing
        end
      end

      class FundingInstrument < Base
        def self.load_members
          object_of :credit_card, CreditCard
          object_of :credit_card_token, CreditCardToken
        end
      end

      class CreditCard < Base
        def self.load_members
          object_of :id, String
          object_of :number, String
          object_of :type, String
          object_of :expire_month, Integer
          object_of :expire_year, Integer
          object_of :cvv2, String
          object_of :first_name, String
          object_of :last_name, String
          object_of :billing_address, Address
          object_of :external_customer_id, String
          object_of :state, String
          object_of :valid_until, String
          object_of :create_time, String
          object_of :update_time, String
          array_of :links, Links
        end

        include RequestDataType

        def create()
          path = "v1/vault/credit-cards"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/vault/credit-cards/#{resource_id}"
            self.new(api.get(path))
          end
        end

        def delete()
          path = "v1/vault/credit-cards/#{self.id}"
          response = api.delete(path, {})
          self.merge!(response)
          success?
        end

        def update(patch_requests)
          patch_request_array = []
          patch_requests.each do |patch_request|
            patch_request = Patch.new(patch_request) unless patch_request.is_a? Patch
            patch_request_array << patch_request.to_hash
          end
          path = "v1/vault/credit-cards/#{self.id}"
          response = api.patch(path, patch_request_array, http_header)
          self.merge!(response)
          success?
        end

        raise_on_api_error :create, :update, :delete
      end

      class BaseAddress < Base
        def self.load_members
          object_of :line1, String
          object_of :line2, String
          object_of :city, String
          object_of :country_code, String
          object_of :postal_code, String
          object_of :state, String
          object_of :normalization_status, String
          object_of :status, String
          object_of :type, String
        end
      end

      class Address < BaseAddress
        def self.load_members
          object_of :phone, String
        end
      end

      class InvoiceAddress < BaseAddress
        def self.load_members
          object_of :phone, Phone
        end
      end

      class OneOf < Base
        def self.load_members
          object_of :phone, Phone
        end
      end

      class CreditCardToken < Base
        def self.load_members
          object_of :credit_card_id, String
          object_of :payer_id, String
          object_of :last4, String
          object_of :type, String
          object_of :expire_month, Integer
          object_of :expire_year, Integer
        end
      end

      class PaymentCard < Base
        def self.load_members
          object_of :id, String
          object_of :number, String
          object_of :type, String
          object_of :expire_month, Integer
          object_of :expire_year, Integer
          object_of :start_month, String
          object_of :start_year, String
          object_of :cvv2, String
          object_of :first_name, String
          object_of :last_name, String
          object_of :billing_country, String
          object_of :billing_address, Address
          object_of :external_customer_id, String
          object_of :status, String
          object_of :card_product_class, String
          object_of :valid_until, String
          object_of :issue_number, String
        end
      end

      class BankAccount < Base
        def self.load_members
          object_of :id, String
          object_of :account_number, String
          object_of :account_number_type, String
          object_of :routing_number, String
          object_of :account_type, String
          object_of :account_name, String
          object_of :check_type, String
          object_of :auth_type, String
          object_of :auth_capture_timestamp, String
          object_of :bank_name, String
          object_of :country_code, String
          object_of :first_name, String
          object_of :last_name, String
          object_of :birth_date, String
          object_of :billing_address, Address
          object_of :state, String
          object_of :confirmation_status, String
          object_of :payer_id, String
          object_of :external_customer_id, String
          object_of :merchant_id, String
          object_of :create_time, String
          object_of :update_time, String
          object_of :valid_until, String
        end

        include RequestDataType

        def create()
          path = "v1/vault/bank-accounts"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/vault/bank-accounts/#{resource_id}"
            self.new(api.get(path))
          end
        end

        def delete()
          path = "v1/vault/bank-accounts/#{self.id}"
          response = api.delete(path, {})
          self.merge!(response)
          success?
        end

        def update(patch_request)
          patch_request = PatchRequest.new(patch_request) unless patch_request.is_a? PatchRequest
          path = "v1/vault/bank-accounts/#{self.id}"
          response = api.patch(path, patch_request.to_hash, http_header)
          self.merge!(response)
          success?
        end

        raise_on_api_error :create, :update, :delete
      end

      class ExtendedBankAccount < BankAccount
        def self.load_members
          object_of :mandate_reference_number, String
        end
      end

      class BankToken < Base
        def self.load_members
          object_of :bank_id, String
          object_of :external_customer_id, String
          object_of :mandate_reference_number, String
        end
      end

      class Credit < Base
        def self.load_members
          object_of :id, String
          object_of :type, String
        end
      end

      class Incentive < Base
        def self.load_members
          object_of :id, String
          object_of :code, String
          object_of :name, String
          object_of :description, String
          object_of :minimum_purchase_amount, Currency
          object_of :logo_image_url, String
          object_of :expiry_date, String
          object_of :type, String
          object_of :terms, String
        end
      end

      class Currency < Base
        def self.load_members
          object_of :currency, String
          object_of :value, String
        end
      end

      class CarrierAccountToken < Base
        def self.load_members
          object_of :carrier_account_id, String
          object_of :external_customer_id, String
        end
      end

      class FundingOption < Base
        def self.load_members
          object_of :id, String
          array_of  :funding_sources, FundingSource
          object_of :backup_funding_instrument, FundingInstrument
          object_of :currency_conversion, CurrencyConversion
          object_of :installment_info, InstallmentInfo
        end
      end

      class FundingSource < Base
        def self.load_members
          object_of :funding_mode, String
          object_of :funding_instrument_type, String
          object_of :soft_descriptor, String
          object_of :amount, Currency
          object_of :negative_balance_amount, Currency
          object_of :legal_text, String
          object_of :terms, String
          object_of :funding_detail, FundingDetail
          object_of :additional_text, String
          object_of :extends, FundingInstrument
          object_of :negative_balance_amount, Currency
          object_of :links, Links
        end
      end

      class FundingDetail < Base
        def self.load_members
          object_of :clearing_time, String
          object_of :payment_hold_date, String
          object_of :payment_debit_date, String
          object_of :processing_type, String
        end
      end

      class CurrencyConversion < Base
        def self.load_members
          object_of :conversion_date, String
          object_of :from_currency, String
          object_of :from_amount, Number
          object_of :to_currency, String
          object_of :to_amount, Number
          object_of :conversion_type, String
          object_of :conversion_type_changeable, Boolean
          object_of :web_url, String
        end
      end

      class InstallmentInfo < Base
        def self.load_members
          object_of :installment_id, String
          object_of :network, String
          object_of :issuer, String
          array_of  :installment_options, InstallmentOption
        end
      end

      class InstallmentOption < Base
        def self.load_members
          object_of :term, Integer
          object_of :monthly_payment, Currency
          object_of :discount_amount, Currency
          object_of :discount_percentage, Percentage
        end
      end

      class Percentage < Base
        def self.load_members
        end
      end

      class PayerInfo < Base
        def self.load_members
          object_of :email, String
          object_of :external_remember_me_id, String
          object_of :buyer_account_number, String
          object_of :salutation, String
          object_of :first_name, String
          object_of :middle_name, String
          object_of :last_name, String
          object_of :suffix, String
          object_of :payer_id, String
          object_of :phone, String
          object_of :phone_type, String
          object_of :birth_date, String
          object_of :tax_id, String
          object_of :tax_id_type, String
          object_of :country_code, String
          object_of :billing_address, Address
          object_of :shipping_address, ShippingAddress
        end
      end

      class ShippingAddress < Base
        def self.load_members
          object_of :line1, String
          object_of :line2, String
          object_of :city, String
          object_of :state, String
          object_of :postal_code, String
          object_of :country_code, String
          object_of :phone, String
          object_of :normalization_status, String
          object_of :id, String
          object_of :recipient_name, String
        end
      end

      class AllOf < Base
        def self.load_members
          array_of  :related_resources, RelatedResources
        end
      end

      class Transaction < Base
        def self.load_members
          object_of :amount, Amount
          object_of :payee, Payee
          object_of :description, String
          object_of :invoice_number, String
          object_of :custom, String
          object_of :soft_descriptor, String
          object_of :item_list, ItemList
          object_of :notify_url, String
          object_of :purchase_unit_reference_id, String
          array_of  :related_resources, RelatedResources
          array_of  :transactions, Transaction
          object_of :payment_options, PaymentOptions
        end
      end

      class CartBase < Base
        def self.load_members
          object_of :amount, Amount
          object_of :payee, Payee
          object_of :description, String
          object_of :note_to_payee, String
          object_of :custom, String
          object_of :invoice_number, String
          object_of :soft_descriptor, String
          object_of :payment_options, PaymentOptions
          object_of :item_list, ItemList
          object_of :notify_url, String
          object_of :order_url, String
          object_of :reference_id, String
        end
      end

      class Amount < Base
        def self.load_members
          object_of :currency, String
          object_of :total, String
          object_of :details, Details
        end
      end

      class Details < Base
        def self.load_members
          object_of :subtotal, String
          object_of :shipping, String
          object_of :tax, String
          object_of :fee, String
          object_of :handling_fee, String
          object_of :shipping_discount, String
          object_of :insurance, String
          object_of :gift_wrap, String
        end
      end

      class Payee < Base
        def self.load_members
          object_of :email, String
          object_of :merchant_id, String
          object_of :phone, Phone
        end
      end

      class Phone < Base
        def self.load_members
          object_of :country_code, String
          object_of :national_number, String
          object_of :extension, String
        end
      end

      class PaymentOptions < Base
        def self.load_members
          object_of :allowed_payment_method, String
        end
      end

      class Item < Base
        def self.load_members
          object_of :sku, String
          object_of :name, String
          object_of :description, String
          object_of :quantity, String
          object_of :price, String
          object_of :currency, String
          object_of :tax, String
          object_of :url, String
          object_of :category, String
          object_of :weight, Measurement
          object_of :length, Measurement
          object_of :height, Measurement
          object_of :width, Measurement
          array_of  :supplementary_data, NameValuePair
          array_of  :postback_data, NameValuePair
        end
      end

      class Measurement < Base
        def self.load_members
          object_of :value, String
          object_of :unit, String
        end
      end

      class NameValuePair < Base
        def self.load_members
          object_of :name, String
          object_of :value, String
        end
      end

      class ItemList < Base
        def self.load_members
          array_of  :items, Item
          object_of :shipping_address, ShippingAddress
          object_of :shipping_method, String
          object_of :shipping_phone_number, String
        end
      end

      class RelatedResources < Base
        def self.load_members
          object_of :sale, Sale
          object_of :authorization, Authorization
          object_of :order, Order
          object_of :capture, Capture
          object_of :refund, Refund
        end
      end

      class Sale < Base
        def self.load_members
          object_of :id, String
          object_of :purchase_unit_reference_id, String
          object_of :amount, Amount
          object_of :payment_mode, String
          object_of :state, String
          object_of :reason_code, String
          object_of :protection_eligibility, String
          object_of :protection_eligibility_type, String
          object_of :clearing_time, String
          object_of :recipient_fund_status, String
          object_of :payment_hold_status, String
          object_of :hold_reason, String
          object_of :transaction_fee, Currency
          object_of :receivable_amount, Currency
          object_of :exchange_rate, String
          object_of :fmf_details, FmfDetails
          object_of :receipt_id, String
          object_of :parent_payment, String
          object_of :create_time, String
          object_of :update_time, String
          array_of  :links, Links
          object_of :billing_agreement_id, String
          object_of :payment_hold_reasons, String
          object_of :processor_response, ProcessorResponse
        end

        include RequestDataType

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/sale/#{resource_id}"
            self.new(api.get(path))
          end
        end

        def refund(refund)
          refund = Refund.new(refund) unless refund.is_a? Refund
          path = "v1/payments/sale/#{self.id}/refund"
          response = api.post(path, refund.to_hash, http_header)
          Refund.new(response)
        end

        def refund_request(refund_request)
          refund_request = RefundRequest.new(refund_request) unless refund_request.is_a? RefundRequest
          path = "v1/payments/sale/#{self.id}/refund"
          response = api.post(path, refund_request.to_hash, http_header)
          DetailedRefund.new(response)
        end

      end

      class AnyOf < Base
        def self.load_members
          object_of :refund, Refund
        end
      end

      class Authorization < Base
        def self.load_members
          object_of :id, String
          object_of :amount, Amount
          object_of :payment_mode, String
          object_of :state, String
          object_of :reason_code, String
          object_of :protection_eligibility, String
          object_of :protection_eligibility_type, String
          object_of :fmf_details, FmfDetails
          object_of :parent_payment, String
          object_of :valid_until, String
          object_of :create_time, String
          object_of :update_time, String
          object_of :reference_id, String
          object_of :receipt_id, String
          array_of  :links, Links
        end

        include RequestDataType

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/authorization/#{resource_id}"
            self.new(api.get(path))
          end
        end

        def capture(capture)
          capture = Capture.new(capture) unless capture.is_a? Capture
          path = "v1/payments/authorization/#{self.id}/capture"
          response = api.post(path, capture.to_hash, http_header)
          Capture.new(response)
        end

        def void()
          path = "v1/payments/authorization/#{self.id}/void"
          response = api.post(path, {}, http_header)
          self.merge!(response)
          success?
        end

        def reauthorize()
          path = "v1/payments/authorization/#{self.id}/reauthorize"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        raise_on_api_error :capture, :void, :reauthorize
      end

      class Order < Base
        def self.load_members
          object_of :id, String
          object_of :purchase_unit_reference_id, String # Deprecated - use :reference_id instead
          object_of :reference_id, String
          object_of :amount, Amount
          object_of :payment_mode, String
          object_of :state, String
          object_of :reason_code, String
          object_of :pending_reason, String
          object_of :protection_eligibility, String
          object_of :protection_eligibility_type, String
          object_of :parent_payment, String
          object_of :fmf_details, FmfDetails
          object_of :create_time, String
          object_of :update_time, String
          array_of  :links, Links
        end

        include RequestDataType

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/orders/#{resource_id}"
            self.new(api.get(path))
          end
        end

        def capture(capture)
          capture = Capture.new(capture) unless capture.is_a? Capture
          path = "v1/payments/orders/#{self.id}/capture"
          response = api.post(path, capture.to_hash, http_header)
          Capture.new(response)
        end

        def void()
          path = "v1/payments/orders/#{self.id}/do-void"
          response = api.post(path, {}, http_header)
          self.merge!(response)
          success?
        end

        def authorize()
          path = "v1/payments/orders/#{self.id}/authorize"
          response = api.post(path, self.to_hash, http_header)
          Authorization.new(response)
        end

        raise_on_api_error :capture, :void, :authorize
      end

      class Capture < Base
        def self.load_members
          object_of :id, String
          object_of :amount, Amount
          object_of :is_final_capture, Boolean
          object_of :state, String
          object_of :reason_code, String
          object_of :parent_payment, String
          object_of :invoice_number, String
          object_of :transaction_fee, Currency
          object_of :create_time, String
          object_of :update_time, String
          array_of  :links, Links
        end

        include RequestDataType

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/capture/#{resource_id}"
            self.new(api.get(path))
          end
        end

        # Deprecated - please use refund_request
        def refund(refund)
          refund = Refund.new(refund) unless refund.is_a? Refund
          path = "v1/payments/capture/#{self.id}/refund"
          response = api.post(path, refund.to_hash, http_header)
          Refund.new(response)
        end

        def refund_request(refund_request)
          refund_request = RefundRequest.new(refund_request) unless refund_request.is_a? RefundRequest
          path = "v1/payments/capture/#{self.id}/refund"
          response = api.post(path, refund_request.to_hash, http_header)
          DetailedRefund.new(response)
        end
      end

      class Refund < Base
        def self.load_members
          object_of :id, String
          object_of :amount, Amount
          object_of :state, String
          object_of :reason, String
          object_of :invoice_number, String
          object_of :sale_id, String
          object_of :capture_id, String
          object_of :parent_payment, String
          object_of :description, String
          object_of :create_time, String
          object_of :update_time, String
          object_of :reason_code, String
          array_of  :links, Links
        end

        include RequestDataType

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/refund/#{resource_id}"
            self.new(api.get(path))
          end
        end
      end

      class RefundRequest < Base
        def self.load_members
          object_of :amount, Amount
          object_of :description, String
          object_of :refund_type, String
          object_of :refund_source, String
          object_of :reason, String
          object_of :invoice_number, String
          object_of :refund_advice, Boolean
          object_of :is_non_platform_transaction, String
        end
      end

      class DetailedRefund < Refund
        def self.load_members
          object_of :custom, String
          object_of :invoice_number, String
          object_of :refund_to_payer, Currency
          array_of  :refund_to_external_funding, ExternalFunding
          object_of :refund_from_transaction_fee, Currency
          object_of :refund_from_received_amount, Currency
          object_of :total_refunded_amount, Currency
        end
      end

      class Error < Base
        def self.load_members
          object_of :name, String
          object_of :debug_id, String
          object_of :message, String
          object_of :code, String
          object_of :information_link, String
          array_of  :details, ErrorDetails
          array_of  :links, Links
        end
      end

      class ErrorDetails < Base
        def self.load_members
          object_of :field, String
          object_of :issue, String
          object_of :code, String
        end
      end

      class FmfDetails < Base
        def self.load_members
          object_of :filter_type, String
          object_of :filter_id, String
          object_of :name, String
          object_of :description, String
        end
      end

      class PaymentInstruction < Base
        def self.load_members
          object_of :reference_number, String
          object_of :instruction_type, String
          object_of :recipient_banking_instruction, RecipientBankingInstruction
          object_of :amount, Currency
          object_of :payment_due_date, String
          object_of :note, String
          array_of  :links, Links
        end

        include RequestDataType

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/payments/payment/#{resource_id}/payment-instruction"
            self.new(api.get(path))
          end
        end
      end

      class RecipientBankingInstruction < Base
        def self.load_members
          object_of :bank_name, String
          object_of :account_holder_name, String
          object_of :account_number, String
          object_of :routing_number, String
          object_of :international_bank_account_number, String
          object_of :bank_identifier_code, String
        end
      end

      class RedirectUrls < Base
        def self.load_members
          object_of :return_url, String
          object_of :cancel_url, String
        end
      end

      class Patch < Base
        def self.load_members
          object_of :op, String
          object_of :path, String
          object_of :value, Object
          object_of :from, String
        end
      end

      class PatchRequest < Base
        def self.load_members
              object_of :op, String
              object_of :path, String
              object_of :value, Object
              object_of :from, String
        end

      end
      class PaymentExecution < Base
        def self.load_members
          object_of :payer_id, String
          object_of :carrier_account_id, String
          array_of  :transactions, CartBase
        end
      end

      class PaymentHistory < Base
        def self.load_members
          array_of  :payments, Payment
          object_of :count, Integer
          object_of :next_id, String
        end
      end

      class CreditCardList < Base
        def self.load_members
          array_of  :items, CreditCard
          object_of :total_items, Integer
          object_of :total_pages, Integer
          array_of :links, Links
        end

        class << self
          def list(options={})
            # for entire list of filter options, see https://developer.paypal.com/webapps/developer/docs/api/#list-credit-card-resources
            path = "v1/vault/credit-cards"
            response = api.get(path, options)
            self.new(response)
          end
        end
      end

      class BankAccountsList < Base
        def self.load_members
          array_of  :bank_accounts, BankAccount
          object_of :count, Integer
          object_of :next_id, String
        end
      end

      class InvoiceAmountWrapper < Base
        def self.load_members
          object_of :paypal, Currency
        end
      end

      class Invoice < Base
        def self.load_members
          object_of :id, String
	      object_of :number, String
	      object_of :template_id, String
	      object_of :uri, String
	      object_of :status, String
	      object_of :merchant_info, MerchantInfo
	      array_of  :billing_info, BillingInfo
	      array_of  :cc_info, Participant
	      object_of :shipping_info, ShippingInfo
	      array_of  :items, InvoiceItem
	      object_of :invoice_date, String
	      object_of :payment_term, PaymentTerm
	      object_of :reference, String
	      object_of :discount, Cost
	      object_of :shipping_cost, ShippingCost
	      object_of :custom, CustomAmount
	      object_of :allow_partial_payment, Boolean
	      object_of :minimum_amount_due, Currency
	      object_of :tax_calculated_after_discount, Boolean
	      object_of :tax_inclusive, Boolean
	      object_of :terms, String
	      object_of :note, String
	      object_of :merchant_memo, String
	      object_of :logo_url, String
	      object_of :total_amount, Currency
          array_of  :payments, PaymentDetail
          array_of  :refunds, RefundDetail
	      object_of :metadata, Metadata
	      object_of :additional_data, String
	      object_of :gratuity, Currency
	      object_of :paid_amount, PaymentSummary
	      object_of :refunded_amount, PaymentSummary
          array_of  :attachments, FileAttachment
          array_of  :links, Links
        end

        include RequestDataType

        def create()
          path = "v1/invoicing/invoices"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def send_invoice()
          path = "v1/invoicing/invoices/#{self.id}/send"
          response = api.post(path, {}, http_header)
          self.merge!(response)
          success?
        end

        def remind(notification)
          notification = Notification.new(notification) unless notification.is_a? Notification
          path = "v1/invoicing/invoices/#{self.id}/remind"
          response = api.post(path, notification.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def cancel(cancel_notification)
          cancel_notification = CancelNotification.new(cancel_notification) unless cancel_notification.is_a? CancelNotification
          path = "v1/invoicing/invoices/#{self.id}/cancel"
          response = api.post(path, cancel_notification.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def record_payment(payment_detail)
          payment_detail = PaymentDetail.new(payment_detail) unless payment_detail.is_a? PaymentDetail
          path = "v1/invoicing/invoices/#{self.id}/record-payment"
          response = api.post(path, payment_detail.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def record_refund(refund_detail)
          refund_detail = RefundDetail.new(refund_detail) unless refund_detail.is_a? RefundDetail
          path = "v1/invoicing/invoices/#{self.id}/record-refund"
          response = api.post(path, refund_detail.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def update()
          path = "v1/invoicing/invoices/#{self.id}"
          response = api.put(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def delete()
          path = "v1/invoicing/invoices/#{self.id}"
          response = api.delete(path, {})
          self.merge!(response)
          success?
        end

        raise_on_api_error :create, :send_invoice, :remind, :cancel,
                           :record_payment, :record_refund, :update, :delete

        #
        class << self
          def search(options, access_token = nil)
            path = "v1/invoicing/search"
            api.token = access_token unless access_token.nil?
            response = api.post(path, options)
            Invoices.new(response)
          end

          def find(resource_id, access_token = nil)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/invoicing/invoices/#{resource_id}"
            api.token = access_token unless access_token.nil?
            self.new(api.get(path))
          end

          def get_all(options = {}, access_token = nil)
            path = "v1/invoicing/invoices/"
            api.token = access_token unless access_token.nil?
            Invoices.new(api.get(path, options))
          end

          def qr_code(options = {})
            path = "v1/invoicing/invoices/{invoice_id}/qr-code"
            object.new(api.get(path, options))
          end

          def self.generate_number(options)
            path = "v1/invoicing/invoices/next-invoice-number"
            response = api.post(path, options)
            object.new(response)
          end
        end
      end

      class Participant < Base
        def self.load_members
	            object_of :email, String
	            object_of :first_name, String
	            object_of :last_name, String
	            object_of :business_name, String
	            object_of :phone, Phone
	            object_of :fax, Phone
	            object_of :website, String
	            object_of :additional_info, String
	            object_of :address, Address
        end
      end

      class Template < Base

        def self.load_members
	            object_of :template_id, String
	            object_of :name, String
	            object_of :default, Boolean
	            object_of :template_data, TemplateData
	            array_of  :settings, TemplateSettings
	            object_of :unit_of_measure, String
	            object_of :custom, Boolean
	            array_of  :links, Links
        end

        include RequestDataType

        def delete()
          path = "v1/invoicing/templates/#{self.template_id}"
          response = api.delete(path, {})
          self.merge!(response)
          success?
        end

        def update()
          path = "v1/invoicing/templates/#{self.template_id}"
          response = api.put(path, self.to_hash, http_header)
          self.merge!(response)
          Template.new(response)
        end

        def create()
            path = "v1/invoicing/templates"
            response = api.post(path, self.to_hash, http_header)
            self.merge!(response)
            Template.new(response)
        end

        class << self
          def get(template_id, options = {})
            raise ArgumentError.new("template_id required") if template_id.to_s.strip.empty?
            path = "v1/invoicing/templates/#{template_id}"
            self.new(api.get(path, options))
          end
        end
      end

      class TemplateData < Base

        def self.load_members
	            object_of :merchant_info, MerchantInfo
	            array_of  :billing_info, BillingInfo
	            array_of  :cc_info, String
	            object_of :shipping_info, ShippingInfo
	            array_of  :items, InvoiceItem
	            object_of :payment_term, PaymentTerm
	            object_of :reference, String
	            object_of :discount, Cost
	            object_of :shipping_cost, ShippingCost
	            object_of :custom, CustomAmount
	            object_of :allow_partial_payment, Boolean
	            object_of :minimum_amount_due, Currency
	            object_of :tax_calculated_after_discount, Boolean
	            object_of :tax_inclusive, Boolean
	            object_of :terms, String
	            object_of :note, String
	            object_of :merchant_memo, String
	            object_of :logo_url, String
	            object_of :total_amount, Currency
	            array_of  :attachments, FileAttachment
        end

      end

      class TemplateSettings < Base

        def self.load_members
	            object_of :field_name, String
	            object_of :display_preference, TemplateSettingsMetadata
        end
      end

      class TemplateSettingsMetadata < Base

        def self.load_members
	            object_of :hidden, Boolean
        end

      end

      class PaymentSummary < Base
        def self.load_members
	            object_of :paypal, Currency
	            object_of :other, Currency
        end
      end
      class FileAttachment < Base

        def self.load_members
	            object_of :name, String
	            object_of :url, String
        end

      end
      class Templates < Base

        def self.load_members
	          array_of  :addresses, Address
	          array_of  :emails, String
	          array_of  :phones, Phone
	          array_of  :templates, Template
	          array_of  :links, Links
        end

        include RequestDataType

        class << self
          def get_all(options = {})
            path = "v1/invoicing/templates/"
            Templates.new(api.get(path, options))
          end
        end
      end

      class WebhooksEventType < Base
        def self.load_members
          array_of :event_types, EventType
        end

        include RequestDataType

        class << self
          def all(options = {})
            path = "v1/notifications/webhooks-event-types"
            EventTypeList.new(api.get(path, options))
          end
        end
      end

      class EventTypeList < Base
        def self.load_members
          array_of  :event_types, EventType
        end
      end

      class WebhookList < Base
        def self.load_members
          array_of  :webhooks, Webhook
        end
      end

      class EventType < Base
        def self.load_members
          object_of :name, String
          object_of :description, String
          object_of :status, String
        end
      end

      class WebhookEventList < Base
        def self.load_members
          object_of :count, Integer
          array_of  :events, WebhookEvent
          array_of :links, Links
        end
      end

      class WebhookEvent < Base
        def self.load_members
          object_of :id, String
          object_of :create_time, String
          object_of :resource_type, String
          object_of :event_version, String
          object_of :event_type, String
          object_of :summary, String
          object_of :status, String
          object_of :resource, Hash
          array_of  :links, Links
        end

        def resend()
          path = "v1/notifications/webhooks-events/#{self.id}/resend"
          WebhookEvent.new(api.post(path))
        end

        def get_resource()
          webhook_resource_type = self.resource_type
          resource_class = self.class.get_resource_class(webhook_resource_type)
          if resource_class
            return Object::const_get(resource_class).new(self.resource)
          else
            return self.resource
          end
        end

        include RequestDataType

        class << self

          def get_cert(cert_url)
            data = Net::HTTP.get_response(URI.parse(cert_url))
            cert = OpenSSL::X509::Certificate.new data.body
          end

          def get_cert_chain()
            root_cert = File.expand_path(File.join(File.dirname(__FILE__), '../../../data/DigiCertHighAssuranceEVRootCA.pem'))
            intermediate_cert = File.expand_path(File.join(File.dirname(__FILE__), '../../../data/DigiCertSHA2ExtendedValidationServerCA.pem'))

            cert_store = OpenSSL::X509::Store.new
            cert_store.add_file(root_cert)
            cert_store.add_file(intermediate_cert)

            cert_store
          end

          def get_expected_sig(transmission_id, timestamp, webhook_id, event_body)
            utf8_encoded_event_body = event_body.force_encoding("UTF-8")
            crc = Zlib::crc32(utf8_encoded_event_body).to_s
            transmission_id + "|" + timestamp + "|" + webhook_id + "|" + crc
          end

          def verify_common_name(cert)
            common_name = cert.subject.to_a.select{|name, _, _| name == 'CN' }.first[1]

            common_name.start_with?("messageverificationcerts.") && common_name.end_with?(".paypal.com")
          end

          def verify_signature(transmission_id, timestamp, webhook_id, event_body, cert, actual_sig_encoded, algo)
            expected_sig = get_expected_sig(transmission_id, timestamp, webhook_id, event_body)

            digest = OpenSSL::Digest.new(algo)
            digest.update(expected_sig)
            actual_sig = Base64.decode64(actual_sig_encoded).force_encoding('UTF-8')

            cert.public_key.verify(digest, actual_sig, expected_sig)
          end

          def verify_expiration(cert)
            cert.not_after >= Time.now
          end

          def verify_cert_chain(cert_store, cert)
            cert_store.verify(cert)
          end

          def verify_cert(cert)
            cert_store = get_cert_chain()

            verify_cert_chain(cert_store, cert) && verify_common_name(cert) && verify_expiration(cert)
          end

          def verify(transmission_id, timestamp, webhook_id, event_body, cert_url, sig, algo='sha256')
            cert = get_cert(cert_url)
            verify_signature(transmission_id, timestamp, webhook_id, event_body, cert, sig, algo) && verify_cert(cert)
          end

          def get_resource_class(name)
            class_array = PayPal::SDK::REST.constants.select {|c| Class === PayPal::SDK::REST.const_get(c)}
            class_array.each do |classname|
              if (classname.to_s.downcase == name.downcase)
                return classname
              end
            end
          end

          def search(page_size, start_time, end_time)
            path = "v1/notifications/webhooks-events"
            options = { :page_size => page_size, :start_time => start_time, :end_time => end_time }
            WebhookEventList.new(api.get(path, options))
          end

          def get(webhook_event_id)
            WebhookEvent.find(webhook_event_id)
          end

          def find(resource_id)
            raise ArgumentError.new("webhook_event_id required") if resource_id.to_s.strip.empty?
            path = "v1/notifications/webhooks-events/#{resource_id}"
            self.new(api.get(path))
          end

          def all(options = {})
            path = "v1/notifications/webhooks-events"
            WebhookEventList.new(api.get(path, options))
          end
        end
      end

      class Webhook < Base

        def self.load_members
          object_of :id, String
          object_of :url, String
          array_of  :event_types, EventType
          array_of  :links, Links
        end

        include RequestDataType

        def create()
          path = "v1/notifications/webhooks"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          Webhook.new(response)
        end

        def update(patch)
          patch = Patch.new(patch) unless patch.is_a? Patch
          patch_request = Array.new(1, patch.to_hash)
          path = "v1/notifications/webhooks/#{self.id}"
          response = api.patch(path, patch_request, http_header)
          self.merge!(response)
          success?
        end

        def delete()
          path = "v1/notifications/webhooks/#{self.id}"
          response = api.delete(path, {})
          self.merge!(response)
          success?
        end

        raise_on_api_error :update, :delete

        class << self
          def get(webhook_id)
            raise ArgumentError.new("webhook_id required") if webhook_id.to_s.strip.empty?
            path = "v1/notifications/webhooks/#{webhook_id}"
            Webhook.new(api.get(path))
          end

          def get_event_types(webhook_id)
            raise ArgumentError.new("webhook_id required") if webhook_id.to_s.strip.empty?
            path = "v1/notifications/webhooks/#{webhook_id}/event-types"
            EventTypeList.new(api.get(path))
          end

          def all(options={})
            path = "v1/notifications/webhooks"
            WebhookList.new(api.get(path))
          end

          def simulate_event(webhook_id, url, event_type)
            path = "v1/notifications/simulate-event"
            options = { :webhook_id => webhook_id, :url => url, :event_type => event_type }
            response = api.post(path, options)
            WebhookEvent.new(response)
          end
        end
      end

      class Payout < Base

        def self.load_members
            object_of :sender_batch_header, PayoutSenderBatchHeader
            array_of  :items, PayoutItem
        end

        include RequestDataType

        def create(sync_mode = false)
          path = "v1/payments/payouts"
          options = { :sync_mode => sync_mode }
          response = api.post(path, self.to_hash, http_header, options)
          PayoutBatch.new(response)
        end

        class << self
          def get(payout_batch_id, options = {})
            raise ArgumentError.new("id required") if payout_batch_id.to_s.strip.empty?
            path = "v1/payments/payouts/#{payout_batch_id}"
            PayoutBatch.new(api.get(path, options))
          end
        end
      end
      class PayoutItem < Base

        def self.load_members
              object_of :recipient_type, String
              object_of :amount, Currency
              object_of :note, String
              object_of :receiver, String
              object_of :sender_item_id, String
        end

        include RequestDataType

        class << self
          def get(payout_item_id)
            raise ArgumentError.new("payout_item_id required") if payout_item_id.to_s.strip.empty?
            path = "v1/payments/payouts-item/#{payout_item_id}"
            PayoutItemDetails.new(api.get(path))
          end
          def cancel(payout_item_id)
            raise ArgumentError.new("payout_item_id required") if payout_item_id.to_s.strip.empty?
            path = "v1/payments/payouts-item/#{payout_item_id}/cancel"
            PayoutItemDetails.new(api.post(path))
          end
        end

      end
      class PayoutItemDetails < Base

        def self.load_members
              object_of :payout_item_id, String
              object_of :transaction_id, String
              object_of :transaction_status, String
              object_of :payout_item_fee, Currency
              object_of :payout_batch_id, String
              object_of :sender_batch_id, String
              object_of :payout_item, PayoutItem
              object_of :time_processed, String
              object_of :errors, Error
              array_of  :links, Links
        end

      end
      class PayoutBatch < Base

        def self.load_members
            object_of :batch_header, PayoutBatchHeader
            array_of  :items, PayoutItemDetails
            array_of  :links, Links
        end

      end
      class PayoutBatchHeader < Base

        def self.load_members
              object_of :payout_batch_id, String
              object_of :batch_status, String
              object_of :time_created, String
              object_of :time_completed, String
              object_of :sender_batch_header, PayoutSenderBatchHeader
              object_of :amount, Currency
              object_of :fees, Currency
              object_of :errors, Error
        end

      end
      class PayoutSenderBatchHeader < Base

        def self.load_members
              object_of :sender_batch_id, String
              object_of :email_subject, String
              object_of :recipient_type, String
        end

      end
      class Invoices < Base
        def self.load_members
          object_of :total_count, Integer
          array_of  :invoices, Invoice
        end
      end

      class InvoiceItem < Base
        def self.load_members
	        object_of :name, String
	        object_of :description, String
	        object_of :quantity, Number
	        object_of :unit_price, Currency
	        object_of :tax, Tax
	        object_of :date, String
	        object_of :discount, Cost
	        object_of :image_url, String
	        object_of :unit_of_measure, String
        end
      end

      class MerchantInfo < Base
        def self.load_members
	        object_of :email, String
	        object_of :first_name, String
	        object_of :last_name, String
	        object_of :address, Address
	        object_of :business_name, String
	        object_of :phone, Phone
	        object_of :fax, Phone
	        object_of :website, String
	        object_of :tax_id, String
	        object_of :additional_info_label, String
	        object_of :additional_info, String
        end
      end

      class BillingInfo < Base
        def self.load_members
          object_of :email, String
          object_of :first_name, String
          object_of :last_name, String
          object_of :business_name, String
          object_of :address, InvoiceAddress
          object_of :language, String
          object_of :additional_info, String
          object_of :notification_channel, String
          object_of :phone, Phone

          define_method "address=" do |value|
            if value.is_a?(Address)
              value = value.to_hash
            end
            object = convert_object(value, InvoiceAddress)
            instance_variable_set("@address", object)
          end

          define_method "address" do |&block|
            default_value = PayPal::SDK::Core::Util::OrderedHash.new
            value = instance_variable_get("@address") || ( default_value && (send("address=", default_value)))
            value = convert_object(value.to_hash, Address)
            value
          end

          define_method "invoice_address=" do |value|
            object = convert_object(value, InvoiceAddress)
            instance_variable_set("@address", object)
          end

          define_method "invoice_address" do |&block|
            default_value = PayPal::SDK::Core::Util::OrderedHash.new
            value = instance_variable_get("@address") || ( default_value && (send("address=", default_value)))
            value
          end
        end
      end

      class ShippingInfo < Base
        def self.load_members
          object_of :first_name, String
          object_of :last_name, String
          object_of :business_name, String
          object_of :address, InvoiceAddress
          object_of :email, String

          define_method "address=" do |value|
            if value.is_a?(Address)
              value = value.to_hash
            end
            object = convert_object(value, InvoiceAddress)
            instance_variable_set("@address", object)
          end

          define_method "address" do |&block|
            default_value = PayPal::SDK::Core::Util::OrderedHash.new
            value = instance_variable_get("@address") || ( default_value && (send("address=", default_value)))
            value = convert_object(value.to_hash, Address)
            value
          end

          define_method "invoice_address=" do |value|
            object = convert_object(value, InvoiceAddress)
            instance_variable_set("@address", object)
          end

          define_method "invoice_address" do |&block|
            default_value = PayPal::SDK::Core::Util::OrderedHash.new
            value = instance_variable_get("@address") || ( default_value && (send("address=", default_value)))
            value
          end
        end
      end

      class InvoicingNotification < Base
        def self.load_members
          object_of :subject, String
          object_of :note, String
          object_of :send_to_merchant, Boolean
          array_of  :cc_emails, String
        end
      end

      class InvoicingMetaData < Base
        def self.load_members
          object_of :created_date, String
          object_of :created_by, String
          object_of :cancelled_date, String
          object_of :cancelled_by, String
          object_of :last_updated_date, String
          object_of :last_updated_by, String
          object_of :first_sent_date, String
          object_of :last_sent_date, String
          object_of :last_sent_by, String
        end
      end

      class InvoicingPaymentDetail < Base
        def self.load_members
          object_of :type, String
          object_of :transaction_id, String
          object_of :transaction_type, String
          object_of :date, String
          object_of :method, String
          object_of :note, String
        end
      end

      class InvoicingRefundDetail < Base
        def self.load_members
          object_of :type, String
          object_of :date, String
          object_of :note, String
        end
      end

      class InvoicingSearch < Base
        def self.load_members
          object_of :email, String
          object_of :recipient_first_name, String
          object_of :recipient_last_name, String
          object_of :recipient_business_name, String
          object_of :number, String
          object_of :status, String
          object_of :lower_total_amount, Currency
          object_of :upper_total_amount, Currency
          object_of :start_invoice_date, String
          object_of :end_invoice_date, String
          object_of :start_due_date, String
          object_of :end_due_date, String
          object_of :start_payment_date, String
          object_of :end_payment_date, String
          object_of :start_creation_date, String
          object_of :end_creation_date, String
          object_of :page, Number
          object_of :page_size, Number
          object_of :total_count_required, Boolean
          object_of :archived, Boolean
        end
      end

      class PaymentTerm < Base
        def self.load_members
          object_of :term_type, String
          object_of :due_date, String
        end
      end

      class Cost < Base
        def self.load_members
          object_of :percent, Number
          object_of :amount, Currency
        end
      end

      class ShippingCost < Base
        def self.load_members
          object_of :amount, Currency
          object_of :tax, Tax
        end
      end

      class Tax < Base
        def self.load_members
          object_of :id, String
          object_of :name, String
          object_of :percent, Number
          object_of :amount, Currency
        end
      end

      class CustomAmount < Base
        def self.load_members
          object_of :label, String
          object_of :amount, Currency
        end
      end

      class PaymentDetail < Base
        def self.load_members
          object_of :type, String
          object_of :transaction_id, String
          object_of :transaction_type, String
          object_of :date, String
          object_of :method, String
          object_of :note, String
          object_of :amount, Currency
        end
      end

      class RefundDetail < Base
        def self.load_members
          object_of :type, String
          object_of :date, String
          object_of :note, String
        end
      end

      class Metadata < Base
        def self.load_members
          object_of :created_date, String
          object_of :created_by, String
          object_of :cancelled_date, String
          object_of :cancelled_by, String
          object_of :last_updated_date, String
          object_of :last_updated_by, String
          object_of :first_sent_date, String
          object_of :last_sent_date, String
          object_of :last_sent_by, String
          object_of :payer_view_url, String
        end
      end

      class Notification < Base
        def self.load_members
          object_of :subject, String
          object_of :note, String
          object_of :send_to_merchant, Boolean
        end
      end

      class Search < Base
        def self.load_members
          object_of :email, String
          object_of :recipient_first_name, String
          object_of :recipient_last_name, String
          object_of :recipient_business_name, String
          object_of :number, String
          object_of :status, String
          object_of :lower_total_amount, Currency
          object_of :upper_total_amount, Currency
          object_of :start_invoice_date, String
          object_of :end_invoice_date, String
          object_of :start_due_date, String
          object_of :end_due_date, String
          object_of :start_payment_date, String
          object_of :end_payment_date, String
          object_of :start_creation_date, String
          object_of :end_creation_date, String
          object_of :page, Number
          object_of :page_size, Number
          object_of :total_count_required, Boolean
        end
      end

      class CancelNotification < Base
        def self.load_members
          object_of :subject, String
          object_of :note, String
          object_of :send_to_merchant, Boolean
          object_of :send_to_payer, Boolean
        end
      end

      class Plan < Base
        def self.load_members
          object_of :id, String
          object_of :name, String
          object_of :description, String
          object_of :type, String
          object_of :state, String
          object_of :create_time, String
          object_of :update_time, String
          array_of  :payment_definitions, PaymentDefinition
          array_of  :terms, Terms
          object_of :merchant_preferences, MerchantPreferences
          array_of  :links, Links
        end

        include RequestDataType

        def create()
          path = "v1/payments/billing-plans/"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def update(patch)
          patch = Patch.new(patch) unless patch.is_a? Patch
          patch_request = Array.new(1, patch.to_hash)
          path = "v1/payments/billing-plans/#{self.id}"
          response = api.patch(path, patch_request, http_header)
          self.merge!(response)
          success?
        end

        raise_on_api_error :create, :update

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/billing-plans/#{resource_id}"
            self.new(api.get(path))
          end

          def all(options = {})
            path = "v1/payments/billing-plans/"
            PlanList.new(api.get(path, options))
          end
        end
      end

      class PaymentDefinition < Base
        def self.load_members
          object_of :id, String
          object_of :name, String
          object_of :type, String
          object_of :frequency_interval, String
          object_of :frequency, String
          object_of :cycles, String
          object_of :amount, Currency
          array_of  :charge_models, ChargeModels
        end
      end

      class ChargeModels < Base
        def self.load_members
          object_of :id, String
          object_of :type, String
          object_of :amount, Currency
        end
      end

      class Terms < Base
        def self.load_members
          object_of :id, String
          object_of :type, String
          object_of :max_billing_amount, Currency
          object_of :occurrences, String
          object_of :amount_range, Currency
          object_of :buyer_editable, String
        end
      end

      class MerchantPreferences < Base
        def self.load_members
          object_of :id, String
          object_of :setup_fee, Currency
          object_of :cancel_url, String
          object_of :return_url, String
          object_of :notify_url, String
          object_of :max_fail_attempts, String
          object_of :auto_bill_amount, String
          object_of :initial_fail_amount_action, String
          object_of :accepted_payment_type, String
          object_of :char_set, String
        end
      end

      class Links < Base
        def self.load_members
          object_of :href, String
          object_of :rel, String
          object_of :targetSchema, HyperSchema
          object_of :method, String
          object_of :encType, String
          object_of :schema, HyperSchema
        end
      end

      class Schema < Base
        def self.load_members
          object_of :type, Object
          object_of :properties, Schema
          object_of :patternProperties, Schema
          object_of :additionalProperties, Object
          object_of :items, Object
          object_of :additionalItems, Object
          object_of :required, Boolean
          object_of :dependencies, Object
          object_of :minimum, Number
          object_of :maximum, Number
          object_of :exclusiveMinimum, Boolean
          object_of :exclusiveMaximum, Boolean
          object_of :minItems, Integer
          object_of :maxItems, Integer
          object_of :uniqueItems, Boolean
          object_of :pattern, String
          object_of :minLength, Integer
          object_of :maxLength, Integer
          array_of  :enum, Array
          object_of :title, String
          object_of :description, String
          object_of :format, String
          object_of :divisibleBy, Number
          object_of :disallow, Object
          object_of :extends, Object
          object_of :id, String
          object_of :$ref, String
          object_of :$schema, String
        end
      end

      class HyperSchema < Schema
        def self.load_members
          array_of  :links, Links
          object_of :fragmentResolution, String
          object_of :readonly, Boolean
          object_of :contentEncoding, String
          object_of :pathStart, String
          object_of :mediaType, String
        end
      end

      class PlanList < Base
        def self.load_members
          array_of  :plans, Plan
          object_of :total_items, String
          object_of :total_pages, String
          array_of  :links, Links
        end
      end

      class Agreement < Base
        def self.load_members
              object_of :id, String
              object_of :state, String
              object_of :name, String
              object_of :description, String
              object_of :start_date, String
              object_of :agreement_details, AgreementDetails
              object_of :payer, Payer
              object_of :shipping_address, Address
              object_of :override_merchant_preferences, MerchantPreferences
            array_of  :override_charge_models, OverrideChargeModel
              object_of :plan, Plan
              object_of :create_time, String
              object_of :update_time, String
            array_of  :links, Links
              object_of :token, String
        end

        include RequestDataType

        def create()
          path = "v1/payments/billing-agreements/"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          self.get_token(self.links)
          success?
        end

        def execute()
          path = "v1/payments/billing-agreements/#{self.token}/agreement-execute"
          response = api.post(path, {}, http_header)
          self.merge!(response)
          success?
        end

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/billing-agreements/#{resource_id}"
            self.new(api.get(path))
          end
        end

        def update(patch)
          patch = Patch.new(patch) unless patch.is_a? Patch
          path = "v1/payments/billing-agreements/#{self.id}"
          response = api.patch(path, [patch.to_hash], http_header)
          self.merge!(response)
          success?
        end

        def suspend(agreement_state_descriptor)
          agreement_state_descriptor = AgreementStateDescriptor.new(agreement_state_descriptor) unless agreement_state_descriptor.is_a? AgreementStateDescriptor
          path = "v1/payments/billing-agreements/#{self.id}/suspend"
          response = api.post(path, agreement_state_descriptor.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def re_activate(agreement_state_descriptor)
          agreement_state_descriptor = AgreementStateDescriptor.new(agreement_state_descriptor) unless agreement_state_descriptor.is_a? AgreementStateDescriptor
          path = "v1/payments/billing-agreements/#{self.id}/re-activate"
          response = api.post(path, agreement_state_descriptor.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def cancel(agreement_state_descriptor)
          agreement_state_descriptor = AgreementStateDescriptor.new(agreement_state_descriptor) unless agreement_state_descriptor.is_a? AgreementStateDescriptor
          path = "v1/payments/billing-agreements/#{self.id}/cancel"
          response = api.post(path, agreement_state_descriptor.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def bill_balance(agreement_state_descriptor)
          agreement_state_descriptor = AgreementStateDescriptor.new(agreement_state_descriptor) unless agreement_state_descriptor.is_a? AgreementStateDescriptor
          path = "v1/payments/billing-agreements/#{self.id}/bill-balance"
          response = api.post(path, agreement_state_descriptor.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def set_balance(currency)
          currency = Currency.new(currency) unless currency.is_a? Currency
          path = "v1/payments/billing-agreements/#{self.id}/set-balance"
          response = api.post(path, currency.to_hash, http_header)
          self.merge!(response)
          success?
        end

        raise_on_api_error :create, :execute, :update, :suspend, :re_activate,
                           :cancel, :bill_balance, :set_balance

        class << self
          def transactions(agreement_id, start_date, end_date, options = {})
            path = "v1/payments/billing-agreements/#{agreement_id}/transactions" #?start-date=#{start_date}&end-date=#{end_date}"
            options = { :start_date => start_date, :end_date => end_date }
            AgreementTransactions.new(api.get(path, options))
          end
        end

        def get_token(links)
          links.each do |link|
            if link.rel.eql? "approval_url"
              uri = URI.parse(link.href)
              params = CGI.parse(uri.query)
              self.token = params['token'][0]
              return
            end
          end
        end
      end
      class AgreementDetails < Base
        def self.load_members
          object_of :outstanding_balance, Currency
          object_of :cycles_remaining, String
          object_of :cycles_completed, String
          object_of :next_billing_date, String
          object_of :last_payment_date, String
          object_of :last_payment_amount, Currency
          object_of :final_payment_date, String
          object_of :failed_payment_count, String
        end
      end

      class OverrideChargeModel < Base
        def self.load_members
          object_of :charge_id, String
          object_of :amount, Currency
        end
      end

      class AgreementStateDescriptor < Base
        def self.load_members
          object_of :note, String
          object_of :amount, Currency
        end
      end

      class AgreementTransactions < Base
        def self.load_members
          array_of  :agreement_transaction_list, AgreementTransaction
        end
      end

      class AgreementTransaction < Base
        def self.load_members
          object_of :transaction_id, String
          object_of :status, String
          object_of :transaction_type, String
          object_of :amount, Currency
          object_of :fee_amount, Currency
          object_of :net_amount, Currency
          object_of :payer_email, String
          object_of :payer_name, String
          object_of :time_zone, String
          object_of :time_stamp, DateTime
        end
      end

      class WebProfile < Base
        def self.load_members
          object_of :id, String
          object_of :name, String
          object_of :temporary, Boolean
          object_of :flow_config, FlowConfig
          object_of :input_fields, InputFields
          object_of :presentation, Presentation
        end

        include RequestDataType

        def create()
          path = "v1/payment-experience/web-profiles/"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          WebProfile.new(response)
        end

        def update()
          path = "v1/payment-experience/web-profiles/#{self.id}"
          response = api.put(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def partial_update(patch_request)
          patch_request = PatchRequest.new(patch_request) unless patch_request.is_a? PatchRequest
          path = "v1/payment-experience/web-profiles/#{self.id}"
          response = api.patch(path, patch_request.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def delete()
          path = "v1/payment-experience/web-profiles/#{self.id}"
          response = api.delete(path, {})
          self.merge!(response)
          success?
        end

        raise_on_api_error :update, :partial_update, :delete

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payment-experience/web-profiles/#{resource_id}"
            self.new(api.get(path))
          end

          def get_list(options = {})
            path = "v1/payment-experience/web-profiles/"
            l = api.get(path, options)
            # The API is inconsistent in that it returns an array of WebProfiles
            # instead of a JSON object with a property which should be a list
            # of WebProfiles.
            #
            # Note that the WebProfileList is technically incorrect. It should
            # be a WebProfile.new() here, but due to backwards-compatibility,
            # may need to leave it as WebProfileList.
            l.map { |x| WebProfileList.new(x) }
          end
        end
      end

      class FlowConfig < Base
        def self.load_members
          object_of :landing_page_type, String
          object_of :bank_txn_pending_url, String
          object_of :user_action, String
          object_of :return_uri_http_method, String
        end
      end

      class InputFields < Base
        def self.load_members
          object_of :allow_note, Boolean
          object_of :no_shipping, Integer
          object_of :address_override, Integer
        end
      end

      class Presentation < Base
        def self.load_members
          object_of :brand_name, String
          object_of :logo_image, String
          object_of :locale_code, String
          object_of :return_url_label, String
          object_of :note_to_seller_label, String
        end
      end

      class WebProfileList < Base
        def self.load_members
          object_of :id, String
          object_of :name, String
          object_of :flow_config, FlowConfig
          object_of :input_fields, InputFields
          object_of :presentation, Presentation
          object_of :temporary, Boolean
        end
      end

      constants.each do |data_type_klass|
        data_type_klass = const_get(data_type_klass)
        data_type_klass.load_members if defined? data_type_klass.load_members
      end
    end
  end
end
