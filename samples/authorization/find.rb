# #GetAuthorization Sample
# Sample showing how to retrieve authorized payment details.
# API used: GET /v1/payments/authorization/{authorization_id}
require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

begin
  @authorization = Authorization.find("7WU36907W63353628")
  logger.info "Got Authorization[#{@authorization.id}]"
rescue ResourceNotFound => err
  logger.error "Authorization Not Found"
end
