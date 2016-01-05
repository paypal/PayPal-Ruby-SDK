How to run tests
================

The SDK tests are composed of two groups: unit test group and integration (functional) test group. Integration test group is by default set not to run.

- run a single test
  - `$ bundle exec rspec <test-file>:<line-number>`
  - e.g., to run payment create test,
  - `$ bundle exec rspec spec/payments_examples_spec.rb:53`

- run multiple tests in the same file
  - Add `:<line-number>` to the above command. For example, in order to execute payment create and payment list tests,
  - `$ bundle exec rspec spec/payments_examples_spec.rb:53:95`

- run integration tests
  - This will set the 'integration' flag and will execute functional tests against sandbox.
  - `$ bundle exec rspec --tag integration`
  
- run tests with a specific String
  - `$ bundle exec rspec -e "<string>"`
  - e.g., to run any tests with "Sa" in test description (for the time being, it will be "Sale" tests)
  - `$ bundle exec rspec -e "Sa"`
