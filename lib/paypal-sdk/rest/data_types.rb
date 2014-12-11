require 'paypal-sdk-core'
require 'uuidtools'

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
          @request_id ||= UUIDTools::UUID.random_create.to_s
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

        def self.load_members
        end

        class Number < Float
        end
      end

      class Payment < Base

        def self.load_members
	            object_of :id, String
	            object_of :intent, String
	            object_of :payer, Payer
	            object_of :cart, String
	          array_of  :transactions, Transaction
	          array_of  :failed_transactions, Error
	            object_of :payment_instruction, PaymentInstruction
	            object_of :state, String
	            object_of :experience_profile_id, String
	            object_of :redirect_urls, RedirectUrls
	            object_of :create_time, String
	            object_of :update_time, String
            array_of  :links, Links
        end

        include RequestDataType

        def create()
          path = "v1/payments/payment"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/payment/#{resource_id}"
            self.new(api.get(path))
          end
        end

        def update(patch_request)
          patch_request = PatchRequest.new(patch_request) unless patch_request.is_a? PatchRequest
          path = "v1/payments/payment/#{self.id}"
          response = api.patch(path, patch_request.to_hash, http_header)
          object.new(response)
        end

        def execute(payment_execution)
          payment_execution = PaymentExecution.new(payment_execution) unless payment_execution.is_a? PaymentExecution
          path = "v1/payments/payment/#{self.id}/execute"
          response = api.post(path, payment_execution.to_hash, http_header)
          self.merge!(response)
          success?
        end

        class << self
          def all(options = {})
            path = "v1/payments/payment"
            PaymentHistory.new(api.get(path, options))
          end
        end

      end
      class Payer < Base

        def self.load_members
	            object_of :payment_method, String
	            object_of :status, String
	          array_of  :funding_instruments, FundingInstrument
	            object_of :funding_option_id, String
	            object_of :funding_option, FundingOption
	            object_of :related_funding_option, FundingOption
	            object_of :payer_info, PayerInfo
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
          path = "v1/vault/credit-card"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/vault/credit-card/#{resource_id}"
            self.new(api.get(path))
          end
        end

        def delete()
          path = "v1/vault/credit-card/#{self.id}"
          response = api.delete(path, {})
          self.merge!(response)
          success?
        end

        def update()
          path = "v1/vault/credit-card/#{self.id}"
          response = api.patch(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

      end
      class Address < Base

        def self.load_members
	            object_of :line1, String
	            object_of :line2, String
	            object_of :city, String
	            object_of :country_code, String
	            object_of :postal_code, String
	            object_of :state, String
	            object_of :phone, String
	            object_of :normalization_status, String
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
	            object_of :valid_until, String
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
	            object_of :legal_text, String
	            object_of :funding_detail, FundingDetail
	            object_of :additional_text, String
	            object_of :extends, FundingInstrument
        end

      end
      class FundingDetail < Base

        def self.load_members
	            object_of :clearing_time, String
	            object_of :payment_hold_date, String
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
	            object_of :first_name, String
	            object_of :last_name, String
	            object_of :payer_id, String
	            object_of :phone, String
	            object_of :phone_type, String
	            object_of :birth_date, String
	            object_of :tax_id, String
	            object_of :tax_id_type, String
	            object_of :billing_address, Address
	            object_of :shipping_address, ShippingAddress
        end

      end
      class ShippingAddress < Base

        def self.load_members
          object_of :line1, String
          object_of :city, String
          object_of :state, String
          object_of :postal_code, String
          object_of :country_code, String
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
          array_of  :related_resources, RelatedResources
          array_of  :transactions, Transaction
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
	            object_of :handling_fee, String
	            object_of :shipping_discount, String
	            object_of :insurance, String
	            object_of :gift_wrap, String
        end

      end
      class Payee < Base

        def self.load_members
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
	            object_of :quantity, String
	            object_of :name, String
	            object_of :description, String
	            object_of :price, String
	            object_of :tax, String
	            object_of :currency, String
	            object_of :sku, String
	            object_of :url, String
	            object_of :category, String
	          array_of  :supplementary_data, NameValuePair
	          array_of  :postback_data, NameValuePair
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
        end

      end
      class RelatedResources < Base

        def self.load_members
          object_of :order, Order
          object_of :sale, Sale
          object_of :authorization, Authorization
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
	            object_of :parent_payment, String
	            object_of :create_time, String
	            object_of :update_time, String
            array_of  :links, Links
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
	            object_of :protection_eligibility, String
	            object_of :protection_eligibility_type, String
	            object_of :parent_payment, String
	            object_of :valid_until, String
	            object_of :create_time, String
	            object_of :update_time, String
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

      end
      class Order < Base

        def self.load_members
	            object_of :id, String
	            object_of :purchase_unit_reference_id, String
	            object_of :amount, Amount
	            object_of :payment_mode, String
	            object_of :state, String
	            object_of :pending_reason, String
	            object_of :"protection-eligibility", String
	            object_of :"protection-eligibility_type", String
	            object_of :parent_payment, String
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

      end
      class Capture < Base

        def self.load_members
	            object_of :id, String
	            object_of :amount, Amount
	            object_of :is_final_capture, Boolean
	            object_of :state, String
	            object_of :parent_payment, String
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

        def refund(refund)
          refund = Refund.new(refund) unless refund.is_a? Refund
          path = "v1/payments/capture/#{self.id}/refund"
          response = api.post(path, refund.to_hash, http_header)
          Refund.new(response)
        end

      end
      class Refund < Base

        def self.load_members
	            object_of :id, String
	            object_of :amount, Amount
	            object_of :state, String
	            object_of :reason, String
	            object_of :sale_id, String
	            object_of :capture_id, String
	            object_of :parent_payment, String
	            object_of :description, String
	            object_of :create_time, String
	            object_of :update_time, String
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
      class Error < Base

        def self.load_members
	            object_of :name, String
	            object_of :debug_id, String
	            object_of :message, String
	            object_of :information_link, String
	          array_of  :details, ErrorDetails
        end

      end
      class ErrorDetails < Base

        def self.load_members
	            object_of :field, String
	            object_of :issue, String
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
      class PatchRequest < Base

        def self.load_members
	            object_of :op, String
	            object_of :path, String
        end

      end
      class Patch < Base

        def self.load_members
	            object_of :op, String
	            object_of :path, String
        end

      end
      class PaymentExecution < Base

        def self.load_members
	            object_of :payer_id, String
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
	          array_of  :"credit-cards", CreditCard
	            object_of :count, Integer
	            object_of :next_id, String
        end

      end
      class BankAccountsList < Base

        def self.load_members
	          array_of  :"bank-accounts", BankAccount
	            object_of :count, Integer
	            object_of :next_id, String
        end

      end
      class Invoice < Base

        def self.load_members
	            object_of :id, String
	            object_of :number, String
	            object_of :uri, String
	            object_of :status, String
	            object_of :merchant_info, MerchantInfo
	          array_of  :billing_info, BillingInfo
	            object_of :shipping_info, ShippingInfo
	          array_of  :items, InvoiceItem
	            object_of :invoice_date, String
	            object_of :payment_term, PaymentTerm
	            object_of :discount, Cost
	            object_of :shipping_cost, ShippingCost
	            object_of :custom, CustomAmount
	            object_of :tax_calculated_after_discount, Boolean
	            object_of :tax_inclusive, Boolean
	            object_of :terms, String
	            object_of :note, String
	            object_of :merchant_memo, String
	            object_of :logo_url, String
	            object_of :total_amount, Currency
	          array_of  :payment_details, PaymentDetail
	          array_of  :refund_details, RefundDetail
	            object_of :metadata, Metadata
        end

        include RequestDataType

        def create()
          path = "v1/invoicing/invoices"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        class << self
          def self.search(options)
            path = "v1/invoicing/search"
            response = api.post(path, options)
            Invoices.new(response)
          end
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

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/invoicing/invoices/#{resource_id}"
            self.new(api.get(path))
          end
        end

        class << self
          def get_all(options = {})
            path = "v1/invoicing/invoices/"
            Invoices.new(api.get(path, options))
          end
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
	            object_of :additional_info, String
        end

      end
      class BillingInfo < Base

        def self.load_members
	            object_of :email, String
	            object_of :first_name, String
	            object_of :last_name, String
	            object_of :business_name, String
	            object_of :address, Address
	            object_of :language, String
	            object_of :additional_info, String
        end

      end
      class ShippingInfo < Base

        def self.load_members
	            object_of :first_name, String
	            object_of :last_name, String
	            object_of :business_name, String
	            object_of :address, Address
              object_of :email, String
        end

      end
      class InvoicingNotification < Base

        def self.load_members
	            object_of :subject, String
	            object_of :note, String
	            object_of :send_to_merchant, Boolean
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

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/billing-plans/#{resource_id}"
            self.new(api.get(path))
          end
        end

        def create()
          path = "v1/payments/billing-plans/"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def update(patch_request)
          patch_request = PatchRequest.new(patch_request) unless patch_request.is_a? PatchRequest
          path = "v1/payments/billing-plans/#{self.id}"
          response = api.patch(path, patch_request.to_hash, http_header)
          self.merge!(response)
          success?
        end

        class << self
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
	            object_of :enctype, String
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
	            object_of :name, String
	            object_of :description, String
	            object_of :start_date, String
	            object_of :payer, Payer
	            object_of :shipping_address, Address
	            object_of :override_merchant_preferences, MerchantPreferences
	          array_of  :override_charge_models, OverrideChargeModel
	            object_of :plan, Plan
	            object_of :create_time, String
	            object_of :update_time, String
	          array_of  :links, Links
        end

        include RequestDataType

        def create()
          path = "v1/payments/billing-agreements/"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        def execute()
          path = "v1/payments/billing-agreements/#{self.id}/agreement-execute"
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

        def update(patch_request)
          patch_request = PatchRequest.new(patch_request) unless patch_request.is_a? PatchRequest
          path = "v1/payments/billing-agreements/#{self.id}"
          response = api.patch(path, patch_request.to_hash, http_header)
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

        class << self
          def transactions(options = {})
            path = "v1/payments/billing-agreements/{agreement-id}/transactions"
            AgreementTransactions.new(api.get(path, options))
          end
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
	            object_of :time_updated, String
	            object_of :time_zone, String
        end

      end
      class WebProfile < Base

        def self.load_members
	            object_of :id, String
	            object_of :name, String
	            object_of :flow_config, FlowConfig
	            object_of :input_fields, InputFields
	            object_of :presentation, Presentation
        end

        include RequestDataType

        def create()
          path = "v1/payment-experience/web-profiles/"
          response = api.post(path, self.to_hash, http_header)
          CreateProfileResponse.new(response)
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

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payment-experience/web-profiles/#{resource_id}"
            self.new(api.get(path))
          end
        end

        class << self
          def get_list(options = {})
            path = "v1/payment-experience/web-profiles/"
            WebProfileList.new(api.get(path, options))
          end
        end

        def delete()
          path = "v1/payment-experience/web-profiles/#{self.id}"
          response = api.delete(path, {})
          self.merge!(response)
          success?
        end

      end
      class FlowConfig < Base

        def self.load_members
	            object_of :landing_page_type, String
	            object_of :bank_txn_pending_url, String
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
        end

      end
      class CreateProfileResponse < Base

        def self.load_members
	            object_of :id, String
        end

      end
      class WebProfileList < Base

        def self.load_members
	            object_of :id, String
	            object_of :name, String
	            object_of :flow_config, FlowConfig
	            object_of :input_fields, InputFields
	            object_of :presentation, Presentation
        end

      end

      constants.each do |data_type_klass|
        data_type_klass = const_get(data_type_klass)
        data_type_klass.load_members if defined? data_type_klass.load_members
      end

    end
  end
end
