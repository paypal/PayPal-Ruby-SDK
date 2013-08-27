# #CreatePayment Using Saved Card Sample
# This sample code demonstrates how you can process a
# Payment using a previously saved credit card.
# API used: /v1/payments/payment
require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

# ###Payment
# A Payment Resource; create one using
# the above types and intent as `sale` or `authorize`
@payment = Payment.new({
  :intent => "sale",
  # ###Payer
  # A resource representing a Payer that funds a payment
  # Use the List of `FundingInstrument` and the Payment Method
  # as 'credit_card'
  :payer => {
    :payment_method => "credit_card",

    # ###FundingInstrument
    # A resource representing a Payeer's funding instrument.
    # In this case, a Saved Credit Card can be passed to
    # charge the payment.
    :funding_instruments => [{
      # ###CreditCardToken
      # A resource representing a credit card that can be
      # used to fund a payment.
      :credit_card_token => {
        :credit_card_id => "CARD-47D02392S1941151TKIODGQI" }}]},

  # ###Transaction
  # A transaction defines the contract of a
  # payment - what is the payment for and who
  # is fulfilling it
  :transactions => [{

    # Item List
    :item_list => {
      :items => [{
        :name => "item",
        :sku => "item",
        :price => "1",
        :currency => "USD",
        :quantity => 1 }]},

    # ###Amount
    # Let's you specify a payment amount.
    :amount => {
      :total => "1.00",
      :currency => "USD" },
    :description => "This is the payment transaction description." }]})

# Create Payment and return status
if @payment.create
  logger.info "Payment[#{@payment.id}] created successfully"
else
  logger.error "Error while creating payment:"
  logger.error @payment.error.inspect
end

