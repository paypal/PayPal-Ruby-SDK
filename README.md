# Deprecation Notice:
This SDK is deprecated. You can continue to use it, but no new features or support requests will be accepted.
For alternatives, please visit [the current SDK homepage on the PayPal Developer Portal](https://developer.paypal.com/docs/api/rest-sdks/)

## PayPal REST API Ruby SDK [![Build Status](https://travis-ci.org/paypal/PayPal-Ruby-SDK.svg?branch=master)](https://travis-ci.org/paypal/PayPal-Ruby-SDK) [![Coverage Status](https://coveralls.io/repos/github/paypal/PayPal-Ruby-SDK/badge.svg?branch=master)](https://coveralls.io/github/paypal/PayPal-Ruby-SDK?branch=master)


The PayPal REST SDK provides Ruby APIs to create, process and manage payment.

## PayPal Checkout v2
Please note that if you are integrating with PayPal Checkout, this SDK and corresponding API [v1/payments](https://developer.paypal.com/docs/api/payments/v1/) are in the process of being deprecated.

We recommend that you integrate with API [v2/checkout/orders](https://developer.paypal.com/docs/api/orders/v2/) and [v2/payments](https://developer.paypal.com/docs/api/payments/v2/). Please refer to the [Checkout Ruby SDK](https://github.com/paypal/Checkout-Ruby-SDK) to continue with the integration.


## 2.0 Release Candidate!
We're releasing a [brand new version of our SDK!](https://github.com/paypal/PayPal-Ruby-SDK/tree/2.0-beta) 2.0 is currently at release candidate status, and represents a full refactor, with the goal of making all of our APIs extremely easy to use. 2.0 includes all of the existing APIs, and includes the new Orders API (disputes and Marketplace coming soon). Check out the [FAQ and migration guide](https://github.com/paypal/PayPal-Ruby-SDK/tree/2.0-beta/docs), and let us know if you have any suggestions or issues!

## Prerequisites
- Ruby 2.0.0 or above
- Bundler

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'paypal-sdk-rest'
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install paypal-sdk-rest
```

## Configuration

For Rails application:

```sh
rails g paypal:sdk:install
```

For other ruby application, create a configuration file(`config/paypal.yml`):

```yaml
development: &default
  mode: sandbox
  client_id: EBWKjlELKMYqRNQ6sYvFo64FtaRLRR5BdHEESmha49TM
  client_secret: EO422dn3gQLgDbuwqTjzrFgFtaRLRR5BdHEESmha49TM
  # # with Proxy
  # http_proxy: http://proxy-ipaddress:3129/
  # # with CA File
  # ssl_options:
  #   ca_file: config/cacert.pem
  # # Override Endpoint
  # rest_endpoint: https://api.sandbox.paypal.com
test:
  <<: *default
production:
  mode: live
  client_id: CLIENT_ID
  client_secret: CLIENT_SECRET
```


Load Configurations from specified file:

```ruby
PayPal::SDK::Core::Config.load('spec/config/paypal.yml',  ENV['RACK_ENV'] || 'development')
```

Without configuration file:

```ruby
PayPal::SDK.configure(
  :mode => "sandbox", # "sandbox" or "live"
  :client_id => "EBWKjlELKMYqRNQ6sYvFo64FtaRLRR5BdHEESmha49TM",
  :client_secret => "EO422dn3gQLgDbuwqTjzrFgFtaRLRR5BdHEESmha49TM",
  :ssl_options => { } )
```

Logger configuration:

```ruby
PayPal::SDK.logger = Logger.new(STDERR)

# change log level to INFO
PayPal::SDK.logger.level = Logger::INFO
```
**NOTE**: At `DEBUG` level, all requests/responses are logged except when `mode` is set to `live`. In order to disable request/response printing, set the log level to `INFO` or less verbose ones.


### OpenIDConnect Samples

```ruby
require 'paypal-sdk-rest'

# Update client_id, client_secret and redirect_uri
PayPal::SDK.configure({
  :openid_client_id     => "client_id",
  :openid_client_secret => "client_secret",
  :openid_redirect_uri  => "http://google.com"
})
include PayPal::SDK::OpenIDConnect

# Generate URL to Get Authorize code
puts Tokeninfo.authorize_url( :scope => "openid profile" )

# Create tokeninfo by using AuthorizeCode from redirect_uri
tokeninfo = Tokeninfo.create("Replace with Authorize Code received on redirect_uri")
puts tokeninfo.to_hash

# Refresh tokeninfo object
tokeninfo = tokeninfo.refresh
puts tokeninfo.to_hash

# Create tokeninfo by using refresh token
tokeninfo = Tokeninfo.refresh("Replace with refresh_token")
puts tokeninfo.to_hash

# Get Userinfo
userinfo = tokeninfo.userinfo
puts userinfo.to_hash

# Get logout url
put tokeninfo.logout_url
```

## Create Payment

```ruby
require 'paypal-sdk-rest'
include PayPal::SDK::REST

PayPal::SDK::REST.set_config(
  :mode => "sandbox", # "sandbox" or "live"
  :client_id => "EBWKjlELKMYqRNQ6sYvFo64FtaRLRR5BdHEESmha49TM",
  :client_secret => "EO422dn3gQLgDbuwqTjzrFgFtaRLRR5BdHEESmha49TM")

# Build Payment object
@payment = Payment.new({
  :intent =>  "sale",
  :payer =>  {
    :payment_method =>  "paypal" },
  :redirect_urls => {
    :return_url => "http://localhost:3000/payment/execute",
    :cancel_url => "http://localhost:3000/" },
  :transactions =>  [{
    :item_list => {
      :items => [{
        :name => "item",
        :sku => "item",
        :price => "5",
        :currency => "USD",
        :quantity => 1 }]},
    :amount =>  {
      :total =>  "5",
      :currency =>  "USD" },
    :description =>  "This is the payment transaction description." }]})

if @payment.create
  @payment.id     # Payment Id
else
  @payment.error  # Error Hash
end
```

## Get Payment details

```ruby
# Fetch Payment
payment = Payment.find("PAY-57363176S1057143SKE2HO3A")

# Get List of Payments
payment_history = Payment.all( :count => 10 )
payment_history.payments
```

## Execute Payment

```ruby
payment = Payment.find("PAY-57363176S1057143SKE2HO3A")

if payment.execute( :payer_id => "DUFRQ8GWYMJXC" )
  # Success Message
  # Note that you'll need to `Payment.find` the payment again to access user info like shipping address
else
  payment.error # Error Hash
end
```

## Create Future Payment
[Future Payments](https://developer.paypal.com/docs/integration/mobile/make-future-payment/) sample is available [here](https://github.com/paypal/rest-api-sdk-ruby/blob/master/samples/payment/create_future_payment.rb#L149)

## Webhook event validation
See [webhook event validation code sample](https://github.com/paypal/PayPal-Ruby-SDK/blob/master/samples/notifications/verify_webhook_event.rb) and [webhook event validation docs](https://developer.paypal.com/docs/integration/direct/rest-webhooks-overview/#event-signature)

## OpenID Connect

```ruby
# Update client_id, client_secret and redirect_uri
PayPal::SDK.configure({
  :openid_client_id     => "client_id",
  :openid_client_secret => "client_secret",
  :openid_redirect_uri  => "http://google.com"
})
include PayPal::SDK::OpenIDConnect

# Generate authorize URL to Get Authorize code
puts Tokeninfo.authorize_url( :scope => "openid profile" )

# Create tokeninfo by using Authorize Code from redirect_uri
tokeninfo = Tokeninfo.create("Replace with Authorize Code received on redirect_uri")

# Refresh tokeninfo object
tokeninfo.refresh

# Create tokeninfo by using refresh token
tokeninfo = Tokeninfo.refresh("Replace with refresh_token")

# Get Userinfo
userinfo = tokeninfo.userinfo

# Get Userinfo by using access token
userinfo = Userinfo.get("Replace with access_token")

# Get logout url
logout_url = tokeninfo.logout_url
```
[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/paypal/rest-api-sdk-ruby/trend.png)](https://bitdeli.com/free "Bitdeli Badge")


## Payouts

To make Payouts, you should enable this option in your account at http://developer.paypal.com.

```ruby
@payout = Payout.new(
  {
    :sender_batch_header => {
      :sender_batch_id => SecureRandom.hex(8),
      :email_subject => 'You have a Payout!',
    },
    :items => [
      {
        :recipient_type => 'EMAIL',
        :amount => {
          :value => '1.0',
          :currency => 'USD'
        },
        :note => 'Thanks for your patronage!',
        :receiver => 'shirt-supplier-one@mail.com',
        :sender_item_id => "2014031400023",
      }
    ]
  }
)

begin
  @payout_batch = @payout.create
  logger.info "Created Payout with [#{@payout_batch.batch_header.payout_batch_id}]"
rescue ResourceNotFound => err
  logger.error @payout.error.inspect
end
```

## Direct Credit Card Support
[Braintree Direct](https://www.braintreepayments.com/products/braintree-direct) is PayPal's preferred integration solution for accepting direct credit card payments in your mobile app or website. Braintree, a PayPal service, is the easiest way to accept credit cards, PayPal, and many other payment methods.

## License
Code released under [SDK LICENSE](LICENSE)  

## Contributions 
 Pull requests and new issues are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for details. 
