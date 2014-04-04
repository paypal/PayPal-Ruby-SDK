# REST SDK

The PayPal REST SDK provides Ruby APIs to create, process and manage payment.

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
        :number => "4417119669820331",
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
else
  payment.error # Error Hash
end
```

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
