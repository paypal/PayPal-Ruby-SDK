# #GetPayment Sample
# This sample code demonstrates how you can retrieve
# the details of a payment resource.
# API used: /v1/payments/payment/{payment-id}
require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

begin
  # Retrieve the payment object by calling the
  # `find` method
  # on the Payment class by passing Payment ID
  @payment = Payment.find("PAY-0XL713371A312273YKE2GCNI")
  logger.info "Got Payment Details for Payment[#{@payment.id}]"

rescue ResourceNotFound => err
  # It will throw ResourceNotFound exception if the payment not found
  logger.error "Payment Not Found"
end
