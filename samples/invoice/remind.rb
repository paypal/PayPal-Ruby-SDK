require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

@invoice = Invoice.find("INV2-9CAH-K5G7-2JPL-G4B4")
options = {
  "subject" => "Past due",
  "note" => "Please pay soon",
  "send_to_merchant" => true
}

if @invoice.remind(options)
  logger.info "Invoice[#{@invoice.id}] remind successfully"
else
  logger.error @invoice.error.inspect
end
