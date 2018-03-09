require 'paypal-sdk-rest'
require './runner.rb'

include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

begin
    @webhook_event = WebhookEvent.get 'WH-7Y7254563A4550640-11V2185806837105M'
    @webhook_event.resend
    logger.info "Resent Webhook Event[#{@webhook_event.id}]"

rescue ResourceNotFound => err
  logger.error @webhook.error.inspect
end
