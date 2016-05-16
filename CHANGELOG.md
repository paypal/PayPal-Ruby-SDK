PayPal Node SDK release notes
=============================

1.4.4
------
  * Update on Invoicing API changes [#189](https://github.com/paypal/PayPal-Ruby-SDK/pull/189)

1.4.3
------
  * Fix issue where uninitialized constant PayPal::SDK::Core::API::Merchant occurs for merchant-sdk-ruby issue [#184](https://github.com/paypal/PayPal-Ruby-SDK/issues/184)

1.4.2
------
  * Fix test category [#178](https://github.com/paypal/PayPal-Ruby-SDK/issues/178)
  * Delete code irrelevant to REST APIs [#179](https://github.com/paypal/PayPal-Ruby-SDK/issues/179)
  * Fix OpenSSL::X509::StoreError: system lib error for webhook validation [#170](https://github.com/paypal/PayPal-Ruby-SDK/issues/170)
  * Fix incorrect warning message when using DEBUG logging on live [#182](https://github.com/paypal/PayPal-Ruby-SDK/pull/182)

1.4.1
------
  * Fix Webhook common name verification

1.4.0
------
  * Fix CreditCard.update()
  * Payment API support
  * Updated TLS warning message

1.3.4
------
  * Fix payment.update() [#163](https://github.com/paypal/PayPal-Ruby-SDK/issues/163)
  * Include openssl version in user-agent header
  * Add TLS 1.2 support

1.3.3
------
  * Added failover for capturing debug ID
  * Enabled verbose payload logging [#146](https://github.com/paypal/PayPal-Ruby-SDK/issues/146)
  * Removed `time_updated` field in agreement_transaction per [API change](https://developer.paypal.com/webapps/developer/docs/api/#agreementtransaction-object)
  * Removed `payment_details` field in invoice per [API change](https://developer.paypal.com/webapps/developer/docs/api/#invoice-object)
  * Added `payment_options` field to Transaction per [API change](https://developer.paypal.com/webapps/developer/docs/api/#transaction-object)
  * Added secure logging to avoid logging confidential data (e.g., credit card number)
 
1.3.2
------
  * Fixed webprofile.create()
  * Fixed webprofile.get_list()
  * Updated webprofile test cases

1.3.1
------
  * Added CreditCard list() support
  * Added request/response body debugging statements
  * Fixed future payment support, moved sample code, and added docs [#137](https://github.com/paypal/PayPal-Ruby-SDK/issues/137)

1.3.0 - June 30, 2015
----------------------
  * Added Webhook validation

1.2.2 - June 17, 2015
---------------------
  * Fixed NameError due to underscore in variable name
  * Fixed Vault endpoints

1.2.1 - May 21, 2015
--------------------
  * Paypal-Debug-Id printed for any exception

1.2.0 - March 3, 2015
----------------------
  * Webhook management API support added

1.1.2 - March 3, 2015
----------------------
  * Updated payment data models

1.1.1 - February 5, 2015
-------------------------
  * Packaged paypal cert in gem

1.1.0 - February 4, 2015
------------------------
  * Added Payouts support
  * Improved sample page layout

1.0.0 - January 27, 2015
-----------------------
  * Merged sdk-core-ruby with paypal-ruby-sdk

0.10.0 - January 7, 2015
------------------------
  * Added subscription (billing plan and agreement) support

0.9.1 - December 19, 2014
-------------------------
  * Separated out extended data types (future payment)

0.9.0 - December 15, 2014
-------------------------
  * Added payment-experience (web profiles) support
  * Added test execution guide

0.8.0 - December 11, 2014
-------------------------
  * Added order/auth/capture support
  * Grouped tests in 2 categories: unit tests, integration(functional) tests
  * Disabled some tests that involve manual steps (e.g., log in to PayPal website)

0.7.3 - November 21, 2014
-------------------------
  * Changed Correlation ID header for future payment
  * Added data model for Order/Auth/Capture

0.7.2 - October 20, 2014
------------------------
  * Added Order support

0.7.1 - October 8, 2014
-----------------------
  * Added Auth support

0.7.0 - July 1, 2014
--------------------
  * Added future payment support

0.6.1 - Apr 04, 2014
--------------------
  * Added support for Invoice APIs

0.6.0 - May 30, 2013
--------------------
  * Added support for Auth and Capture APIs

0.5.1 - Apr 26, 2013
--------------------
  * Update core version to 0.2.3 for OpenID Connect

0.5.0 - Mar 07, 2013
--------------------
  * Initial Release
