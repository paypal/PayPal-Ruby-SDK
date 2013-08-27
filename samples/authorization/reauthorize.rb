# #Reauthorization Sample
# Sample showing how to do a reauthorization.
# API used: POST /v1/payments/authorization/{authorization_id}/reauthorize
require 'paypal-sdk-rest'
require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging
begin
  # ###Reauthorization
  # Retrieve a authorization id from authorization object
  # by making a Payment with payment type as `PayPal` with intent
  # as `authorize`. You can reauthorize a payment only once 4 to 29
  # days after 3-day honor period for the original authorization
  # expires.
  @authorization = Authorization.find("7GH53639GA425732B")
  
  @authorization.amount = {
      :currency => "USD",
      :total => "7.00" };
  
  if @authorization.reauthorize # Return true or false
    logger.info "Reauthorization[#{@authorization.id}]"
  else
    logger.error @authorization.error.inspect
  end
rescue ResourceNotFound => err
  # It will throw ResourceNotFound exception if the payment not found
  logger.error "Authorization Not Found"
end