## PayPal REST API Ruby SDK [![Build Status](https://travis-ci.org/paypal/PayPal-Ruby-SDK.png?branch=master)](https://travis-ci.org/paypal/PayPal-Ruby-SDK)

The PayPal REST SDK provides Ruby APIs to create, process and manage payment.

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
  :intent => "sale",
  :payer => {
    :payment_method => "credit_card",
    :funding_instruments => [{
      :credit_card => {
        :type => "visa",
        :number => "4567516310777851",
        :expire_month => "11",
        :expire_year => "2018",
        :cvv2 => "874",
        :first_name => "Joe",
        :last_name => "Shopper",
        :billing_address => {
          :line1 => "52 N Main ST",
          :city => "Johnstown",
          :state => "OH",
          :postal_code => "43210",
          :country_code => "US" }}}]},
  :transactions => [{
    :item_list => {
      :items => [{
        :name => "item",
        :sku => "item",
        :price => "1",
        :currency => "USD",
        :quantity => 1 }]},
    :amount => {
      :total => "1.00",
      :currency => "USD" },
    :description => "This is the payment transaction description." }]})

# Create Payment and return the status(true or false)
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

Only for [Payment](https://github.com/paypal/rest-api-sdk-ruby/blob/master/samples/payment/create_with_paypal.rb) with `payment_method` as `"paypal"`

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
## License
Code released under [SDK LICENSE](LICENSE)  

## Contributions 
 Pull requests and new issues are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for details. 