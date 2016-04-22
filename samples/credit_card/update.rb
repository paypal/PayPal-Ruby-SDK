# #UpdateCreditCard Sample
# Using the 'vault' API, you can store a 
# Credit Card securely on PayPal. You can
# use a saved Credit Card to process
# a payment in the future.
# The following code demonstrates how 
# can update a Credit Card on PayPal using 
# the Vault API.
# API used: PATCH /v1/vault/credit-card
require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

@credit_card = CreditCard.new({
   # ###CreditCard
   # A resource representing a credit card that can be
   # used to fund a payment.
   :type => "visa",
   :number => "4567516310777851",
   :expire_month => "11",
   :expire_year => "2018",
   :cvv2 => "874",
   :first_name => "Joe",
   :last_name => "Shopper",

    # ###Address
    # Base Address object used as shipping or billing
    # address in a payment. [Optional]
   :billing_address => {
     :line1 => "52 N Main ST",
     :city => "Johnstown",
     :state => "OH",
     :postal_code => "43210",
     :country_code => "US" }})

@patch_requests = [
  {
    :op => "replace",
    :path => "/billing_address",
    :value => {
      "line1": "111 First Street",
      "city": "Saratoga",
      "country_code": "US",
      "state": "CA",
      "postal_code": "95070"
    }
  },
  {
    :op => "replace",
    :path => "/first_name",
    :value => "Mary"
  },
  {
    :op => "replace",
    :path => "/last_name",
    :value => "Shopper"
  }
]

# Make API call & get response status
# ###Save
# Creates the credit card as a resource
# in the PayPal vault. 
if @credit_card.create
  logger.info "CreditCard[#{@credit_card.id}] created successfully"

  # update the newly created credit card
  if @credit_card.update(@patch_requests)
    logger.info "CreditCard[#{@credit_card.id}] updated successfully"
  else
    logger.error "Error while updating CreditCard:"
    logger.error @credit_card.error.inspect
  end

else
  logger.error "Error while creating CreditCard:"
  logger.error @credit_card.error.inspect
end