# #RefundCapture Sample
# Sample showing how to refund captured payment.
# API used: GET /v1/payments/capture/{capture_id}/refund
require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

begin
  @capture = Capture.find("7YR91301C22810733")
  @refund  = @capture.refund({
    :amount => {
      :currency => "USD",
      :total => "0.01" }
  })
  
  # Check refund status
  if @refund.success?
    logger.info "Refund[#{@refund.id}] Success"
  else
    logger.error "Unable to Refund"
    logger.error @refund.error.inspect
  end
rescue ResourceNotFound => err
  # It will throw ResourceNotFound exception if the payment not found
  logger.error "Authorization Not Found"
end