# #Capture Sample
# Sample showing how to capture an authorized payment.
# API used: POST /v1/payments/authorization/{authorization_id}/capture
require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging
begin
  @authorization = Authorization.find("84H59271K1950474X")
  @capture = @authorization.capture({
    :amount => {
      :currency => "USD",
      :total => "1.00" },
    :is_final_capture => true })
  
  if @capture.success? # Return true or false
    logger.info "Capture[#{@capture.id}]"
  else
    logger.error @capture.error.inspect
  end
rescue ResourceNotFound => err
  # It will throw ResourceNotFound exception if the payment not found
  logger.error "Authorization Not Found"
end

