require "spec_helper"
require "securerandom"

describe "Webhooks" do

  webhookAttributes = {
    :url => "https://www.yeowza.com/paypal_webhook_"+SecureRandom.hex(8),
    :event_types => [
        {
            :name => "PAYMENT.AUTHORIZATION.CREATED"
        },
        {
            :name => "PAYMENT.AUTHORIZATION.VOIDED"
        }
    ]
  }

  describe "Notifications", :integration => true do
    it "create webhook" do
      $webhook = PayPal::SDK::REST::Webhook.new(webhookAttributes)
      expect($webhook.create).to be_truthy
    end

    it "get webhook" do
      $result = PayPal::SDK::REST::Webhook.get($webhook.id)
      expect($result).to be_a PayPal::SDK::REST::Webhook
      expect($result.id).to eql $webhook.id
    end

    it "get all webhooks" do
      $webhooks_list = PayPal::SDK::REST::Webhook.all()
      expect($webhooks_list.webhooks.length).not_to be_nil
    end

    it "get subscribed webhook event types" do
      $webhook_event_types = PayPal::SDK::REST::Webhook.get_event_types($webhook.id)
      expect($webhook_event_types.event_types.length).to eql $webhook.event_types.length
    end

    it "delete webhook" do
      expect($webhook.delete).to be_truthy
    end
  end

  describe "Validation", :integration => true do

    transmission_id = "dfb3be50-fd74-11e4-8bf3-77339302725b"
    timestamp = "2015-05-18T15:45:13Z"
    webhook_id = "4JH86294D6297924G"
    actual_signature = "thy4/U002quzxFavHPwbfJGcc46E8rc5jzgyeafWm5mICTBdY/8rl7WJpn8JA0GKA+oDTPsSruqusw+XXg5RLAP7ip53Euh9Xu3UbUhQFX7UgwzE2FeYoY6lyRMiiiQLzy9BvHfIzNIVhPad4KnC339dr6y2l+mN8ALgI4GCdIh3/SoJO5wE64Bh/ueWtt8EVuvsvXfda2Le5a2TrOI9vLEzsm9GS79hAR/5oLexNz8UiZr045Mr5ObroH4w4oNfmkTaDk9Rj0G19uvISs5QzgmBpauKr7Nw++JI0pr/v5mFctQkoWJSGfBGzPRXawrvIIVHQ9Wer48GR2g9ZiApWg=="
    event_body = '{"id":"WH-0G2756385H040842W-5Y612302CV158622M","create_time":"2015-05-18T15:45:13Z","resource_type":"sale","event_type":"PAYMENT.SALE.COMPLETED","summary":"Payment completed for $ 20.0 USD","resource":{"id":"4EU7004268015634R","create_time":"2015-05-18T15:44:02Z","update_time":"2015-05-18T15:44:21Z","amount":{"total":"20.00","currency":"USD"},"payment_mode":"INSTANT_TRANSFER","state":"completed","protection_eligibility":"ELIGIBLE","protection_eligibility_type":"ITEM_NOT_RECEIVED_ELIGIBLE,UNAUTHORIZED_PAYMENT_ELIGIBLE","parent_payment":"PAY-86C81811X5228590KKVNARQQ","transaction_fee":{"value":"0.88","currency":"USD"},"links":[{"href":"https://api.sandbox.paypal.com/v1/payments/sale/4EU7004268015634R","rel":"self","method":"GET"},{"href":"https://api.sandbox.paypal.com/v1/payments/sale/4EU7004268015634R/refund","rel":"refund","method":"POST"},{"href":"https://api.sandbox.paypal.com/v1/payments/payment/PAY-86C81811X5228590KKVNARQQ","rel":"parent_payment","method":"GET"}]},"links":[{"href":"https://api.sandbox.paypal.com/v1/notifications/webhooks-events/WH-0G2756385H040842W-5Y612302CV158622M","rel":"self","method":"GET"},{"href":"https://api.sandbox.paypal.com/v1/notifications/webhooks-events/WH-0G2756385H040842W-5Y612302CV158622M/resend","rel":"resend","method":"POST"}]}'
    cert_url = "https://api.sandbox.paypal.com/v1/notifications/certs/CERT-360caa42-fca2a594-a5cafa77"
    algo = "SHA256withRSA"

    it "verify common name" do
      cert = PayPal::SDK::REST::WebhookEvent.get_cert(cert_url)
      valid = PayPal::SDK::REST::WebhookEvent.verify_common_name(cert)
      expect(valid).to be_truthy
    end

    it "verify get expected signature" do
      expected_sig = PayPal::SDK::REST::WebhookEvent.get_expected_sig(transmission_id, timestamp, webhook_id, event_body)
      expect(expected_sig).eql?("dfb3be50-fd74-11e4-8bf3-77339302725b|2015-05-18T15:45:13Z|4JH86294D6297924G|2771810304")
    end

    it "verify expiry" do
      cert = PayPal::SDK::REST::WebhookEvent.get_cert(cert_url)
      valid = PayPal::SDK::REST::WebhookEvent.verify_expiration(cert)
      expect(valid).to be_truthy
    end

    it "verify cert chain" do
      cert = PayPal::SDK::REST::WebhookEvent.get_cert(cert_url)
      cert_store = PayPal::SDK::REST::WebhookEvent.get_cert_chain
      valid = PayPal::SDK::REST::WebhookEvent.verify_cert_chain(cert_store, cert)
      expect(valid).to be_truthy
    end

    it "verify" do
      valid = PayPal::SDK::REST::WebhookEvent.verify(transmission_id, timestamp, webhook_id, event_body, cert_url, actual_signature, algo)
      expect(valid).to be_truthy
    end

  end

end
