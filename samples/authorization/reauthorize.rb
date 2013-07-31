# #Reauthorization Sample
# Sample showing how to do a reauthorization.
# API used: POST /v1/payments/authorization/{authorization_id}/reauthorize
require 'paypal-sdk-rest'
require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

# ###Reauthorization
# Retrieve a authorization id from authorization object
# by making a `Payment Using PayPal` with intent
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
