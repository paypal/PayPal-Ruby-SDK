require 'spec_helper'

describe "Payments" do

  PaymentAttributes = {
        "intent" =>  "sale",
        "payer" =>  {
          "payment_method" =>  "credit_card",
          "funding_instruments" =>  [ {
            "credit_card" =>  {
              "type" =>  "visa",
              "number" =>  "4417119669820331",
              "expire_month" =>  "11", "expire_year" =>  "2018",
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


  it "Validate user-agent" do
    PayPal::SDK::REST::API.user_agent.should match "PayPalSDK/rest-sdk-ruby"
  end

  describe "Examples" do
    describe "REST" do
      it "Modifiy global configuration" do
        backup_config = PayPal::SDK::REST.api.config
        PayPal::SDK::REST.set_config( :client_id => "XYZ" )
        PayPal::SDK::REST.api.config.client_id.should eql "XYZ"
        PayPal::SDK::REST.set_config(backup_config)
        PayPal::SDK::REST.api.config.client_id.should_not eql "XYZ"
      end
    end

    describe "Payment" do
      it "Create" do
        payment = Payment.new(PaymentAttributes)
        # Create
        payment.create
        payment.error.should be_nil
        payment.id.should_not be_nil
      end

      it "Create with request_id" do
        payment = Payment.new(PaymentAttributes)
        payment.create
        payment.error.should be_nil

        request_id = payment.request_id

        new_payment = Payment.new(PaymentAttributes.merge( :request_id => request_id ))
        new_payment.create
        new_payment.error.should be_nil

        payment.id.should eql new_payment.id

      end

      it "Create with token" do
        api = API.new
        payment = Payment.new(PaymentAttributes.merge( :token => api.token ))
        Payment.api.should_not eql payment.api
        payment.create
        payment.error.should be_nil
        payment.id.should_not be_nil
      end

      it "Create with client_id and client_secret" do
        api = API.new
        payment = Payment.new(PaymentAttributes.merge( :client_id => api.config.client_id, :client_secret => api.config.client_secret))
        Payment.api.should_not eql payment.api
        payment.create
        payment.error.should be_nil
        payment.id.should_not be_nil
      end

      it "List" do
        payment_history = Payment.all( "count" => 5 )
        payment_history.error.should be_nil
        payment_history.count.should eql 5
      end

      it "Find" do
        payment_history = Payment.all( "count" => 1 )
        payment = Payment.find(payment_history.payments[0].id)
        payment.error.should be_nil
      end

      describe "Validation" do

        it "Create with empty values" do
          payment = Payment.new
          payment.create.should be_false
        end

        it "Find with invalid ID" do
          lambda {
            payment = Payment.find("Invalid")
          }.should raise_error PayPal::SDK::Core::Exceptions::ResourceNotFound
        end

        it "Find with nil" do
          lambda{
            payment = Payment.find(nil)
          }.should raise_error ArgumentError
        end

        it "Find with empty string" do
          lambda{
            payment = Payment.find("")
          }.should raise_error ArgumentError
        end

        it "Find record with expired token" do
          lambda {
            Payment.api.token
            Payment.api.token.sub!(/^/, "Expired")
            Payment.all(:count => 1)
          }.should_not raise_error
        end
      end

      describe "instance method" do

        it "Execute" do
          pending "Test with capybara"
        end
      end

    end

    describe "Sale" do
      before :each do
        @payment = Payment.new(PaymentAttributes)
        @payment.create
        @payment.should be_success
      end

      it "Find" do
        sale = Sale.find(@payment.transactions[0].related_resources[0].sale.id)
        sale.error.should be_nil
        sale.should be_a Sale
      end

      describe "instance method" do
        it "Refund" do
          sale   = @payment.transactions[0].related_resources[0].sale
          refund = sale.refund( :amount => { :total => "1.00", :currency => "USD" } )
          refund.error.should be_nil

          refund = Refund.find(refund.id)
          refund.error.should be_nil
          refund.should be_a Refund
        end
      end
    end

    describe "Authorize" do
      before :each do
        @payment = Payment.new(PaymentAttributes.merge( :intent => "authorize" ))
        @payment.create
        @payment.error.should be_nil
      end

      it "Find" do
        authorize = Authorization.find(@payment.transactions[0].related_resources[0].authorization.id)
        authorize.error.should be_nil
        authorize.should be_a Authorization
      end

      it "Capture" do
        authorize = @payment.transactions[0].related_resources[0].authorization
        capture   = authorize.capture({:amount => { :currency => "USD", :total => "1.00" } })
        capture.error.should be_nil
      end

      it "Void" do
        authorize = @payment.transactions[0].related_resources[0].authorization
        authorize.void()
        authorize.error.should be_nil
      end

    end

    describe "Capture" do
      before :each do
        @payment = Payment.new(PaymentAttributes.merge( :intent => "authorize" ))
        @payment.create
        @payment.error.should be_nil
        authorize = @payment.transactions[0].related_resources[0].authorization
        @capture = authorize.capture({:amount => { :currency => "USD", :total => "1.00" } })
        @capture.error.should be_nil
      end

      it "Find" do
        capture = Capture.find(@capture.id)
        capture.error.should be_nil
        capture.should be_a Capture
      end

      it "Refund" do
        refund = @capture.refund({})
        refund.error.should be_nil
      end
    end

    describe "CreditCard" do
      it "Create" do
        credit_card = CreditCard.new({
          "type" =>  "visa",
          "number" =>  "4417119669820331",
          "expire_month" =>  "11", "expire_year" =>  "2018",
          "cvv2" =>  "874",
          "first_name" =>  "Joe", "last_name" =>  "Shopper",
          "billing_address" =>  {
            "line1" =>  "52 N Main ST",
            "city" =>  "Johnstown",
            "state" =>  "OH",
            "postal_code" =>  "43210", "country_code" =>  "US" }})
        credit_card.create
        credit_card.error.should be_nil
        credit_card.id.should_not be_nil

        credit_card = CreditCard.find(credit_card.id)
        credit_card.should be_a CreditCard
        credit_card.error.should be_nil
      end

      it "Delete" do
        credit_card = CreditCard.new({
          "type" =>  "visa",
          "number" =>  "4417119669820331",
          "expire_month" =>  "11", "expire_year" =>  "2018" })
        credit_card.create.should be_true
        credit_card.delete.should be_true
      end

      describe "Validation" do
        it "Create" do
          credit_card = CreditCard.new({
            "type" =>  "visa",
            "number" =>  "4111111111111111" })
          credit_card.create
          credit_card.error.should_not be_nil

          credit_card.error.name.should eql "VALIDATION_ERROR"
          credit_card.error["name"].should eql "VALIDATION_ERROR"

          credit_card.error.details[0].field.should eql "expire_year"
          credit_card.error.details[0].issue.should eql "Required field missing"
          credit_card.error.details[1].field.should eql "expire_month"
          credit_card.error.details[1].issue.should eql "Required field missing"

          credit_card.error["details"][0]["issue"].should eql "Required field missing"
        end
      end

    end

  end
end
