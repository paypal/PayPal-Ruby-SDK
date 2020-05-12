require 'spec_helper'
require 'json'
require 'webmock/rspec'

describe "Payments" do

  PaymentAttributes = {
        "intent" =>  "sale",
        "payer" =>  {
          "payment_method" =>  "credit_card",
          "funding_instruments" =>  [ {
            "credit_card" =>  {
              "type" =>  "visa",
              "number" =>  "4032037558005936",
              "expire_month" =>  "12", "expire_year" =>  "2022",
              "cvv2" =>  "874",
              "first_name" =>  "Joe", "last_name" =>  "Shopper",
              "billing_address" =>  {
                "line1" =>  "52 N Main ST",
                "city" =>  "Johnstown",
                "state" =>  "OH",
                "postal_code" =>  "43210", "country_code" =>  "US" } } } ] },
        "transactions" =>  [ {
          "amount" =>  {
            "total" =>  "1.00",
            "currency" =>  "USD" },
          "description" =>  "This is the payment transaction description." } ] }

  PaymentAttributesPayPal = {
        "intent" =>  "sale",
        "payer" =>  {
          "payment_method" =>  "paypal"
        },
        "redirect_urls" => {
          "return_url" => 'https://localhost/return',
          "cancel_url" => 'https://localhost/cancel',
        },
        "transactions" =>  [ {
          "amount" =>  {
            "total" =>  "1.00",
            "currency" =>  "USD" },
          "description" =>  "This is the payment transaction description." } ] }

  FuturePaymentAttributes = {
        "intent" =>  "authorize",
        "payer" =>  {
          "payment_method" =>  "paypal" },
        "transactions" =>  [ {
          "amount" =>  {
            "total" =>  "1.00",
            "currency" =>  "USD" },
          "description" =>  "This is the payment transaction description." } ] }

  ProcessorErrorResponse = {
    "name" => "INSTRUMENT_DECLINED",
    "message" => "The instrument presented was either declined by the processor or bank, or it can't be used for this payment.",
    "information_link" => "https://developer.paypal.com/docs/api/#INSTRUMENT_DECLINED",
    "debug_id" => "20dcd4f71107c",
    "another_thing" => {
      "avs_code" => "Y",
      "cvv_code" => "N",
      "response_code" => "0051"
    }
  }

  it "Validate user-agent", :unit => true do
    expect(PayPal::SDK::REST::API.user_agent).to match "PayPalSDK/PayPal-Ruby-SDK"
  end

  describe "Examples" do
    describe "REST", :unit => true do
      it "Modifiy global configuration" do
        backup_config = PayPal::SDK::REST.api.config
        PayPal::SDK::REST.set_config( :client_id => "XYZ" )
        expect(PayPal::SDK::REST.api.config.client_id).to eql "XYZ"
        PayPal::SDK::REST.set_config(backup_config)
        expect(PayPal::SDK::REST.api.config.client_id).not_to eql "XYZ"
      end

      it "Create - does not return true when error not provided in response" do
        oauth_response = {
            :scope => "https://uri.paypal.com/services/subscriptions https://api.paypal.com/v1/payments/.* https://api.paypal.com/v1/vault/credit-card https://uri.paypal.com/services/applications/webhooks openid https://uri.paypal.com/payments/payouts https://api.paypal.com/v1/vault/credit-card/.*",
            :nonce => "2016-10-04T18:00:00ZP3PcGAv5XAncoc8Zt4MF5cRLlaEBW3OAoLEhMIFk--g",
            :access_token => "A101.tp_sF5GHqWnnqEQA13Ua5ABnIhRWgd-G9LhRnJdgOvJHc_L08zlfD9WgPF4I3kre.mShauuOGxWyw8ikViItmxkWmX78",
            :token_type => "Bearer",
            :app_id => "APP-80W284485P519543T",
            :expires_in => 30695
        }

        response_headers = {
            "date" => ["Fri, 09 Sep 2016 17:44:23 GMT"],
            "server" => ["Apache"],
            "proxy_server_info" => ["host=dcg12javapapi8768.dcg12.slc.paypalinc.com;threadId=1177"],
            "paypal-debug-id" => ["20dcd4f71107c", "20dcd4f71107c"],
            "correlation-id" => ["20dcd4f71107c"],
            "content-language" => ["*"],
            "connection" => ["close", "close"],
            "set-cookie" => ["X-PP-SILOVER=name%3DLIVE3.API.1%26silo_version%3D880%26app%3Dplatformapiserv%26TIME%3D4160016983%26HTTP_X_PP_AZ_LOCATOR%3Ddcg12.slc; Expires=Fri, 09 Sep 2016 18:14:25 GMT; domain=.paypal.com; path=/; Secure; HttpOnly", "X-PP-SILOVER=; Expires=Thu, 01 Jan 1970 00:00:01 GMT"],
            "vary" => ["Authorization"],
            "content-length" => ["335"],
            "content-type"=>["application/json"]
        }

        stub_request(:post, "https://api.sandbox.paypal.com/v1/oauth2/token")
            .to_return(:body => oauth_response.to_json)

        stub_request(:post, "https://api.sandbox.paypal.com/v1/payments/payment")
            .to_return(:body => ProcessorErrorResponse.to_json, :status => 400, :headers => response_headers)

        payment = Payment.new(PaymentAttributes)
        expect(payment.create).to be_falsey
      end
    end

    describe "Payment", :integration => true do
      it "Create" do
        payment = Payment.new(PaymentAttributes)
        # Create
        payment.create
        expect(payment.error).to be_nil
        expect(payment.id).not_to be_nil
        expect(payment.approval_url).to be_nil
        expect(payment.token).to be_nil
      end

      it "Create with request_id" do
        payment = Payment.new(PaymentAttributes)
        payment.create
        expect(payment.error).to be_nil

        request_id = payment.request_id

        new_payment = Payment.new(PaymentAttributes.merge( :request_id => request_id ))
        new_payment.create
        expect(new_payment.error).to be_nil

        expect(payment.id).to eql new_payment.id
      end

      it "Create with token" do
        api = API.new
        payment = Payment.new(PaymentAttributes.merge( :token => api.token ))
        expect(Payment.api).not_to eql payment.api
        payment.create
        expect(payment.error).to be_nil
        expect(payment.id).not_to be_nil
      end

      it "Create with client_id and client_secret" do
        api = API.new
        payment = Payment.new(PaymentAttributes.merge( :client_id => api.config.client_id, :client_secret => api.config.client_secret))
        expect(Payment.api).not_to eql payment.api
        payment.create
        expect(payment.error).to be_nil
        expect(payment.id).not_to be_nil
      end

      it "Create with redirect urls" do
        payment = Payment.new(PaymentAttributesPayPal)
        # Create
        payment.create
        expect(payment.error).to be_nil
        expect(payment.id).not_to be_nil
        expect(payment.approval_url).to include('webscr?cmd=_express-checkout')
        expect(payment.approval_url).not_to include('useraction=commit')
        expect(payment.approval_url(true)).to eq payment.approval_url + '&useraction=commit'
        expect(payment.token).to match /^EC-[A-Z0-9]+$/
      end

      it "List" do
        payment_history = Payment.all( "count" => 5 )
        expect(payment_history.error).to be_nil
        expect(payment_history.count).to eql 5
      end

      it "Find" do
        payment_history = Payment.all( "count" => 1 )
        payment = Payment.find(payment_history.payments[0].id)
        expect(payment.error).to be_nil
      end

      describe "Validation", :integration => true do

        it "Create with empty values" do
          payment = Payment.new
          expect(payment.create).to be_falsey
        end

        it "Find with invalid ID" do
          expect {
            payment = Payment.find("Invalid")
          }.to raise_error PayPal::SDK::Core::Exceptions::ResourceNotFound
        end

        it "Find with nil" do
          expect{
            payment = Payment.find(nil)
          }.to raise_error ArgumentError
        end

        it "Find with empty string" do
          expect{
            payment = Payment.find("")
          }.to raise_error ArgumentError
        end

        it "Find record with expired token" do
          expect {
            Payment.api.token
            Payment.api.token.sub!(/^/, "Expired")
            Payment.all(:count => 1)
          }.not_to raise_error
        end
      end

      # describe "instance method" do

      #   it "Execute" do
      #     pending "Test with capybara"
      #   end
      # end

    end

    describe "Future Payment", :disabled => true do
      access_token = nil

      it "Exchange Authorization Code for Refresh / Access Tokens" do

        # put your authorization code for testing here
        auth_code = ''

        if auth_code != ''
          tokeninfo  = FuturePayment.exch_token(auth_code)
          expect(tokeninfo.access_token).not_to be_nil
          expect(tokeninfo.refresh_token).not_to be_nil
        end
      end

      it "Create a payment" do
        # put your PAYPAL-CLIENT-METADATA-ID
        correlation_id = ''
        @future_payment = FuturePayment.new(FuturePaymentAttributes.merge( :token => access_token ))
        @future_payment.create(correlation_id)
        expect(@future_payment.error).to be_nil
        expect(@future_payment.id).not_to be_nil
      end

    end

    describe "Sale", :integration => true do
      before :each do
        @payment = Payment.new(PaymentAttributes)
        @payment.create
        expect(@payment).to be_success
      end

      it "Find" do
        sale = Sale.find(@payment.transactions[0].related_resources[0].sale.id)
        expect(sale.error).to be_nil
        expect(sale).to be_a Sale
      end

      describe "instance method" do
        it "Refund" do
          sale   = @payment.transactions[0].related_resources[0].sale
          refund = sale.refund( :amount => { :total => "1.00", :currency => "USD" } )
          expect(refund.error).to be_nil

          refund = Refund.find(refund.id)
          expect(refund.error).to be_nil
          expect(refund).to be_a Refund
        end
      end
    end

    describe "Sale with auth assertion", :integration => true do

      before :each, :disabled => true do
        sale_id = "" #replace with payment sale id
        @sale = Sale.find(sale_id)
        expect(@sale.error).to be_nil
        expect(@sale).to be_a Sale
      end

      describe "instance method" do
        it "Refund", :disabled => true do
          api = API.new();
          payer_id = "" #replace with subject's payer_id
          auth_head = api.auth_assertion_header(payer_id, true)
          refund = @sale.refund( {:amount => { :total => "1.00", :currency => "USD" }, :auth_header => auth_head} )
          expect(refund.error).to be_nil

          refund = Refund.find(refund.id)
          expect(refund.error).to be_nil
          expect(refund).to be_a Refund
        end
      end
    end

    describe "Order", :integration => true do
      it "Find" do
        order   = Order.find("O-2HT09787H36911800")
        expect(order.error).to be_nil
        expect(order).to_not be_nil
      end

      # The following Order tests must be ignored when run in an automated environment because executing an order
      # will require approval via the executed payment's approval_url.

      before :each, :disabled => true do
        @payment = Payment.new(PaymentAttributes.merge( "intent" => "order" ))
        payer_id = "" # replace with the actual payer_id
        @payment.create
        @payment.execute( :payer_id => payer_id )
        expect(@payment.error).to be_nil
      end

      it "Authorize", :disabled => true do
        auth = order.authorize
        expect(auth.state).to eq("Pending")
      end

      it "Capture", :disabled => true do
        capture = Capture.new({
            "amount" => {
              "currency" => "USD",
              "total" => "1.00"
            },
            "is_final_capture" => true
          })
        order = order.capture(@capture)
        expect(order.state).to eq("completed")
      end

      it "Void", :disabled => true do
        order = order.void()
        expect(order.state).to eq("voided")
      end

    end

    describe "Authorize", :integration => true do
      before :each do
        @payment = Payment.new(PaymentAttributes.merge( "intent" => "authorize" ))
        @payment.create
        expect(@payment.error).to be_nil
      end

      it "Find" do
        authorize = Authorization.find(@payment.transactions[0].related_resources[0].authorization.id)
        expect(authorize.error).to be_nil
        expect(authorize).to be_a Authorization
      end

      it "Capture" do
        authorize = @payment.transactions[0].related_resources[0].authorization
        capture   = authorize.capture({:amount => { :currency => "USD", :total => "1.00" } })
        expect(capture.error).to be_nil
      end

      it "Void" do
        authorize = @payment.transactions[0].related_resources[0].authorization
        authorize.void()
        expect(authorize.error).to be_nil
      end

     it "Reauthorization" do
        authorize = Authorization.find("7GH53639GA425732B");
        authorize.amount = { :currency => "USD", :total => "1.00" }
        authorize.reauthorize
        expect(authorize.error).not_to be_nil
      end
    end

    describe "Capture", :integration => true do
      before :each do
        @payment = Payment.new(PaymentAttributes.merge( "intent" => "authorize" ))
        @payment.create
        expect(@payment.error).to be_nil
        authorize = @payment.transactions[0].related_resources[0].authorization
        @capture = authorize.capture({:amount => { :currency => "USD", :total => "1.00" } })
        expect(@capture.error).to be_nil
      end

      it "Find" do
        capture = Capture.find(@capture.id)
        expect(capture.error).to be_nil
        expect(capture).to be_a Capture
      end

      it "Refund" do
        refund = @capture.refund({})
        expect(refund.error).to be_nil
      end
    end

    describe "CreditCard", :integration => true do
      it "Create" do
        credit_card = CreditCard.new({
          "type" =>  "visa",
          "number" =>  "4567516310777851",
          "expire_month" =>  "11", "expire_year" =>  "2018",
          "cvv2" =>  "874",
          "first_name" =>  "Joe", "last_name" =>  "Shopper",
          "billing_address" =>  {
            "line1" =>  "52 N Main ST",
            "city" =>  "Johnstown",
            "state" =>  "OH",
            "postal_code" =>  "43210", "country_code" =>  "US" }})
        credit_card.create
        expect(credit_card.error).to be_nil
        expect(credit_card.id).not_to be_nil

        credit_card = CreditCard.find(credit_card.id)
        expect(credit_card).to be_a CreditCard
        expect(credit_card.error).to be_nil
      end

      it "Delete" do
        credit_card = CreditCard.new({
          "type" =>  "visa",
          "number" =>  "4567516310777851",
          "expire_month" =>  "11", "expire_year" =>  "2018" })
        expect(credit_card.create).to be_truthy
        expect(credit_card.delete).to be_truthy
      end

      describe "Validation", :integration => true do
        it "Create" do
          credit_card = CreditCard.new({
            "type" =>  "visa",
            "number" =>  "4111111111111111" })
          credit_card.create
          expect(credit_card.error).not_to be_nil

          expect(credit_card.error.name).to eql "VALIDATION_ERROR"
          expect(credit_card.error["name"]).to eql "VALIDATION_ERROR"

          expect(credit_card.error.details[0].field).to eql "expire_year"
          expect(credit_card.error.details[0].issue).to eql "Required field missing"
          expect(credit_card.error.details[1].field).to eql "expire_month"
          expect(credit_card.error.details[1].issue).to eql "Required field missing"

          expect(credit_card.error["details"][0]["issue"]).to eql "Required field missing"
        end
      end
    end

    describe 'CreditCardList', :integration => true do

      it "List" do
        options = { :create_time => "2015-03-28T15:33:43Z" }
        credit_card_list = CreditCardList.list()
        expect(credit_card_list.total_items).to be > 0
      end

    end

  end
end
