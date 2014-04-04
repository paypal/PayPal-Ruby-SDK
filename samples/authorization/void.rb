# #Void Sample
# Sample showing how to void an authorized payment.
# API used: POST /v1/payments/authorization/{authorization_id}/void
require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging
begin
  @authorization = Authorization.find("1SU1944563257711X")
  
  if @authorization.void # Return true or false
    logger.info "Void an Authorization[#{@authorization.id}]"
  else
    logger.error @authorization.error.inspect
  end
rescue ResourceNotFound => err
  # It will throw ResourceNotFound exception if the payment not found
  logger.error "Authorization Not Found"
end
