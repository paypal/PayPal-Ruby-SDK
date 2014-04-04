require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

@invoice = Invoice.find("INV2-VHEH-7Q5J-NV6F-RM6V")

if @invoice.send_invoice
  logger.info "Invoice[#{@invoice.id}] send successfully"
else
  logger.error @invoice.error.inspect
end
