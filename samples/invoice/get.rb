require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

begin
  @invoice= Invoice.find("INV2-P6VJ-36HG-BBVT-M2MA")
  logger.info "Got Invoice Details for Invoice[#{@invoice.id}]"

rescue ResourceNotFound => err
  logger.error "Invoice Not Found"
end
