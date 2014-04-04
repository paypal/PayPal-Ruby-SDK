require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

@invoices = Invoice.get_all( :total_count_required => true )
logger.info "Invoices: #{@invoices.total_count}"
