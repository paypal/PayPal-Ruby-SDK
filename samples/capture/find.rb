# #GetCapture Sample
# Sample showing how to retrieve captured payment details.
# API used: GET /v1/payments/capture/{capture_id}
require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

begin
  @capture = Capture.find("7YR91301C22810733")
  logger.info "Got Capture[#{@sale.id}]"
rescue ResourceNotFound => err
  logger.error "Capture Not Found"
end
