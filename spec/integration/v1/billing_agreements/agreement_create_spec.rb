require_relative '../../test_harness'
require_relative '../billing_plans/plan_helper'
require "braintreehttp"

include PayPal::V1::BillingAgreements

describe AgreementCreateRequest do
  it 'successfully makes a request' do
    begin
    plan_response = PlanHelper::create_plan
    plan_id = plan_response.result.id

    PlanHelper::activate_plan(plan_id)

    resp = AgreementHelper::create_agreement(plan_id)

    expect(resp.status_code).to eq(201)
    expect(resp.result).not_to be_nil
    rescue BraintreeHttp::HttpError => e
      puts e.status_code
      puts e.result
    end
  end
end

module AgreementHelper
  def self.build_request_body(plan_id)
    return {
             "name": "Override Agreement",
             "description": "PayPal payment agreement that overrides merchant preferences and shipping fee and tax information.",
             "start_date": (Time.now + 60 * 60 * 24).utc.iso8601,
             "payer": {
               "payment_method": "paypal",
               "payer_info": {
                 "email": "payer@example.com",
               },
             },
             "plan": {
               "id": plan_id,
             },
             "shipping_address": {
               "line1": "Hotel Staybridge",
               "line2": "Crooke Street",
               "city": "San Jose",
               "state": "CA",
               "postal_code": "95112",
               "country_code": "US",
             },
             "override_merchant_preferences": {
               "setup_fee": {
                 "value": "3",
                 "currency": "USD",
               },
               "return_url": "https://example.com/",
               "cancel_url": "https://example.com/cancel",
               "auto_bill_amount": "YES",
               "initial_fail_amount_action": "CONTINUE",
               "max_fail_attempts": "11",
             },
           }
  end

  def self.create_agreement(plan_id)
    request = AgreementCreateRequest.new()
    request.request_body(self.build_request_body(plan_id))

    TestHarness::client.execute(request)
  end
end
