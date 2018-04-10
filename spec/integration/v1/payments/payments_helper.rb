require_relative '../../test_harness'

include PayPal::V1::Payments

module PaymentsHelper
  class << self
    FAKE_ID = 'O-2FK09787H36911800'

    def create_auth_capture(auth_id)
      body = {
        :amount => {
          :total => '10',
          :currency => 'USD'
        },
        :is_final_capture => true
      }

      TestHarness::exec(AuthorizationCaptureRequest.new(auth_id), body)
    end

    def create_payment(intent, payment_method='credit_card', invoice_number=nil)
      body = {
        :intent => intent,
        :transactions => [{
          :amount => {
            :total => '10',
            :currency => 'USD',
          }
        }],
        :redirect_urls => {
          :cancel_url => 'http://example.com/cancel',
          :return_url => 'http://example.com/return',
        }
      }

      if invoice_number
        body[:transactions][0][:invoice_number] = invoice_number
      end

      if payment_method == 'credit_card'
        body[:payer] = {
          :payment_method => 'credit_card',
          :funding_instruments => [{
            :credit_card => {
              :billing_address => {
                :line1 => '123 example ave',
                :line2 => 'apt 4',
                :city => 'Anytown',
                :state => 'CA',
                :postal_code => '12345',
                :country_code => 'US'
              },
              :cvv2 => '617',
              :expire_month => 1,
              :expire_year => 2020,
              :first_name => 'Joe',
              :last_name => 'Shopper',
              :type => 'visa',
              :number => '4422009910903049'
            }
          }]
        }
      else
        body[:payer] = {
          :payment_method => 'paypal'
        }
      end

      begin
        TestHarness::exec(PaymentCreateRequest.new, body)
      rescue BraintreeHttp::HttpError => e
        puts e.status_code
        puts e.result
        throw e
      end
    end
  end
end
