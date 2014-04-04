# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'paypal-sdk/rest/version'

Gem::Specification.new do |gem|
  gem.name          = "paypal-sdk-rest"
  gem.version       = PayPal::SDK::REST::VERSION
  gem.authors       = ["PayPal"]
  gem.email         = ["DL-PP-Platform-Ruby-SDK@ebay.com"]
  gem.summary       = %q{The PayPal REST SDK provides Ruby APIs to create, process and manage payment.}
  gem.description   = %q{The PayPal REST SDK provides Ruby APIs to create, process and manage payment.}
  gem.homepage      = "https://developer.paypal.com"

  gem.files         = Dir["{bin,spec,lib}/**/*"] + ["Rakefile", "README.md", "Gemfile"]
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('paypal-sdk-core', '~> 0.2.8')
  gem.add_dependency('uuidtools', '~> 2.1')
end
