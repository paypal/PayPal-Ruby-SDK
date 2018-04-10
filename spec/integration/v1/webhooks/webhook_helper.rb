require_relative '../../test_harness'

include PayPal::V1::Webhooks

module WebhookHelper
  class << self
    def create_webhook
      delete_all_webhooks

      url = "https://example.com/webook_#{Random.new.rand(1000)}"
      body = {
        :url => url,
        :event_types => [
          {
            :name => 'PAYMENT.AUTHORIZATION.CREATED',
          },
          {
            :name => 'PAYMENT.AUTHORIZATION.VOIDED',
          },
        ]
      }

      TestHarness::exec(WebhookCreateRequest.new, body)
    end

    def delete_all_webhooks
      list_resp = TestHarness::exec(WebhookListRequest.new)

      list_resp.result.webhooks.each do |webhook|
        begin
          delete_webhook(webhook.id)
        rescue Exception => e
          puts "Failed to delete webhook #{webhook.id}"
        end
      end
    end

    def delete_webhook(id)
      TestHarness::exec(WebhookDeleteRequest.new(id))
    end
  end
end
