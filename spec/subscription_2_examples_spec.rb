# rspec spec/subscription_2_examples_spec.rb --example 'Subscription' 
require 'spec_helper'
require 'time'

describe "Subscription" do
	ProductAttributes = {
		"name"=> "The Collegian",
		"description"=> "Official newsletter of CPM University",
		"type"=> "PHYSICAL",
		"category"=> "BOOKS_PERIODICALS_AND_NEWSPAPERS",
		"image_url"=> "https://example.com",
		"home_url"=> "https://example.com"
	}

	SubscriptionPlanAttributes = {
	  "name"=> "Monthy Subscription to the Collegian",
      "status"=> "ACTIVE",
      "description"=> "1 print copy of The Collegian delivered to your address.",
      "billing_cycles"=> [
        {
          "frequency"=> {
            "interval_unit"=> "MONTH",
            "interval_count"=> 1
          },
          "tenure_type"=> "TRIAL",
          "sequence"=> 1,
          "total_cycles"=> 1,
          "pricing_scheme"=> {
            "fixed_price"=> {
              "value"=> "0",
              "currency_code"=> "USD"
            }
          }
        },
        {
          "frequency"=> {
            "interval_unit"=> "MONTH",
            "interval_count"=> 1
          },
          "tenure_type"=> "REGULAR",
          "sequence"=> 2,
          "total_cycles"=> 12,
          "pricing_scheme"=> {
            "fixed_price"=> {
              "value"=> "29.99",
              "currency_code"=> "USD"
            }
          }
        }
      ],
      "payment_preferences"=> {
        "auto_bill_outstanding"=> true,
        "setup_fee"=> {
          "value"=> "5",
          "currency_code"=> "USD"
        },
        "setup_fee_failure_action"=> "CONTINUE",
        "payment_failure_threshold"=> 3
      },
      "taxes"=> {
        "percentage"=> "12",
        "inclusive"=> false
      },
      "quantity_supported"=> true
	}

	start_time = (Time.now + 60).iso8601
	SubscriptionAttributes = {
	  "start_time"=> start_time,
	  "quantity"=> "3",
	  "shipping_amount"=> {
	    "currency_code"=> "USD",
	    "value"=> "9.00"
	  },
	  "subscriber"=> {
	    "name"=> {
	      "given_name"=> "John",
	      "surname"=> "Doe"
	    },
	    "email_address"=> "customer@example.com",
	    "shipping_address"=> {
	      "name"=> {
	        "full_name"=> "John Doe"
	      },
	      "address"=> {
	        "address_line_1"=> "2211 N First Street",
	        "address_line_2"=> "Building 17",
	        "admin_area_2"=> "San Jose",
	        "admin_area_1"=> "CA",
	        "postal_code"=> "95131",
	        "country_code"=> "US"
	      }
	    }
	  },
	  "application_context"=> {
	    "brand_name"=> "The Collegian",
	    "locale"=> "en-US",
	    "shipping_preference"=> "SET_PROVIDED_ADDRESS",
	    "user_action"=> "SUBSCRIBE_NOW",
	    "payment_method"=> {
	      "payer_selected"=> "PAYPAL",
	      "payee_preferred"=> "IMMEDIATE_PAYMENT_REQUIRED"
	    },
	    "return_url"=> "https://example.com/returnUrl",
	    "cancel_url"=> "https://example.com/cancelUrl"
	  }
	}

	PricingSchemeAttributes = 
		{
	      "billing_cycle_sequence"=> 2, #nth billing, must be unique to the plan
	      "pricing_scheme"=> {
	        "fixed_price"=> {
	          "value"=> "35",
	          "currency_code"=> "USD"
	        }
	      }
		}

	OutstandingBalanceAttributes = {
		"currency_code"=> "USD",
		"value"=> "50.00"
	}

	describe "Product", :integration => true do
		it "Create" do
	      $api = API.new
	      $product = Product.new(ProductAttributes.merge( :token => $api.token ))
	      expect(Product.api).not_to eql $product.api
	      $product.create

	      # make sure the transaction was successful
	      $product_id = $product.id
	      expect($product.error).to be_nil
	      expect($product.id).not_to be_nil
	    end

	    it "Find" do
	      api = API.new
	      product = Product.find($product.id)
	      expect(product.id).to eq($product.id)
	      expect(product.name).to eq("The Collegian")
	      expect(product.type).to eq("PHYSICAL")
	    end

	    it "List" do
	    	product_list = Product.all()
      		expect(product_list.error).to be_nil
      		expect(product_list.products.count).to be > 0
	    end
	end

	describe "Plan", :integration => true do
		it "Create" do
			$api = API.new
	    	$plan = SubscriptionPlan.new(SubscriptionPlanAttributes.merge( :token => $api.token ))
	    	$plan.product_id = $product.id	    	
	    	expect(SubscriptionPlan.api).not_to eql $plan.api
	    	$plan.create

	    	# make sure the transaction was successful
	    	$plan_id = $plan.id
	    	expect($plan.error).to be_nil
	    	expect($plan.id).not_to be_nil
		end

		it "Update" do
			# set up a patch request
			patch = Patch.new
			patch.op = "replace"
			patch.path = "/payment_preferences/payment_failure_threshold";
			patch.value = 7
			# the patch request should be successful
			expect($plan.update( patch )).to be_truthy
		end

		it "Deactivate" do
			expect( $plan.deactivate ).to be_truthy
		end

		it "Activate" do
	      expect( $plan.activate ).to be_truthy
		end
		
		it "Update Pricing" do
			$plan = SubscriptionPlan.find($plan_id)
			pricing_schemes = PricingSchemeList.new()
			pricing_schemes.pricing_schemes << PricingSchemeAttributes
			$plan.update_pricing(pricing_schemes)
			expect( $plan.update_pricing(pricing_schemes) ).to be_truthy
		end

		it "Find" do
			plan = SubscriptionPlan.find($plan.id)
			expect(plan.id).to eq($plan.id)
		    expect(plan.name).to eq("Monthy Subscription to the Collegian")
		end

		it "List" do
			plan_list = SubscriptionPlan.all()
      		expect(plan_list.error).to be_nil
      		expect(plan_list.plans.count).to be > 0
		end
	end

	describe "Subscription", :integration => true do
		it "Create" do
			$api = API.new
			$subscription = Subscription.new(SubscriptionAttributes.merge( :token => $api.token ))
			$subscription.plan_id = $plan.id
			$subscription.create

		    expect($subscription.error).to be_nil
		    expect($subscription.id).not_to be_nil
		end

		xit "Find" do
			subscription_id = $subscription.id
			$subscription = Subscription.find(subscription_id)
			expect(subscription_id).to eq($subscription.id)
		    expect($plan.id).to eq($subscription.plan_id)
		end

		it "Approval Link" do 
			expect($subscription.approval_url).to be
		end
		
		xit "Update" do
			$subscription = Subscription.find('I-VPS2DB7LBUSB') #subscription created earlier needs to be approved by the user
			patch = Patch.new
			patch.op = "replace"
			patch.path = "/shipping_amount"
			patch.value = {
		    	"currency_code" => "USD",
    			"value" => "10.0"
		    }
			# the patch request should be successful
			expect($subscription.update( [patch] )).to be_truthy

		end

		xit "Capture" do
			subscription_capture = {
				"note"=> "Charging as the balance reached the limit",
				"capture_type"=> "OUTSTANDING_BALANCE",
				"amount"=> {
					"value"=> "50",
					"currency_code"=> "USD"
					}
				}
			expect($subscription.capture(subscription_capture)).to be_truthy
		end

		xit "Revise" do
			$subscription = Subscription.find("I-E0C12828TYDW")
			revision = {
				"quantity"=> 2
			}
			expect($subscription.revise(revision)).to be_truthy
		end

		xit "Suspend" do 
			reason = {"reason"=>"Closed for Winter break"}
			expect($subscription.suspend(reason)).to be_truthy
		end

		xit "Activate" do
			reason = {"reason"=>"Open for Spring"}
			expect($subscription.activate(reason)).to be_truthy
		end

		xit "Cancel" do
			reason = {"reason"=>"Closing circulation"}
			expect($subscription.cancel(reason)).to be_truthy
		end

		xit "Transactions" do
			start_time = (Time.now - 7200).iso8601
			end_time = (Time.now + 7200).iso8601
			expect($subscription.transactions(start_time, end_time).transactions.count).to be > 0
		end
 	end

end