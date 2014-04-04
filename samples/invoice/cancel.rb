require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

@invoice = Invoice.find("INV2-CJL7-PF4G-BLQF-5FWG")
options = {
  "subject" => "Past due",
  "note" => "Canceling invoice",
  "send_to_merchant" => true,
  "send_to_payer" => true
}

if @invoice.cancel(options)
  logger.info "Invoice[#{@invoice.id}] cancel successfully"
else
  logger.error @invoice.error.inspect
end
