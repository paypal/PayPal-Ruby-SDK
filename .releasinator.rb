#### releasinator config ####
configatron.product_name = "PayPal Ruby SDK"

# List of items to confirm from the person releasing.  Required, but empty list is ok.
configatron.prerelease_checklist_items = [  
  "Sanity check the master branch.", 
  "Unit tests passed.",
  "Functional tests passed."
]

def validate_version_match()
  puts @current_release.version
  if package_version() != @current_release.version
    Printer.fail("Package.json version #{package_version} does not match changelog version #{@current_release.version}.")
    abort()
  end
    Printer.success("Package.json version #{package_version} matches latest changelog version #{@current_release.version}.")
end

def validate_paths
  @validator.validate_in_path("jq")
end

def run_unit_tests
  CommandProcessor.command("bundle exec rspec", live_output=true)
end

def run_functional_tests
  CommandProcessor.command("bundle exec rspec --tag integration", live_output=true)
end

configatron.custom_validation_methods = [
  method(:validate_paths),
  method(:validate_version_match),
  method(:run_unit_tests), 
  method(:run_functional_tests)
]

# there are no separate build steps for PayPal-Cordova-Plugin, so it is just empty method
def build_method
  Rake::Task["build"].invoke
  Rake::Task["release:guard_clean"].invoke
end

# The command that builds the sdk.  Required.
configatron.build_method = method(:build_method)

def publish_to_package_manager(version)
  Rake::Task["release:rubygem_push"].invoke
end

# The method that publishes the sdk to the package manager.  Required.
configatron.publish_to_package_manager_method = method(:publish_to_package_manager)


def wait_for_package_manager(version)
  CommandProcessor.wait_for("wget -U \"non-empty-user-agent\" -qO- https://rubygems.org/gems/paypal-sdk-rest/versions/#{version} | cat")
end

# The method that waits for the package manager to be done.  Required
configatron.wait_for_package_manager_method = method(:wait_for_package_manager)

# Whether to publish the root repo to GitHub.  Required.
configatron.release_to_github = true

def package_version()
  f=File.open("lib/paypal-sdk/rest/version.rb", 'r') do |f|
    f.each_line do |line|
      if line.match (/VERSION = \"\d*\.\d*\.\d*\"/)
        puts line
        return line.strip.split('=')[1].strip.split('"')[1]
      end
    end
  end
end