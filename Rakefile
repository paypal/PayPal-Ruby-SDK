require "bundler/gem_tasks"

desc "Run tests"
task :rspec do
  cmd = "bundle exec rspec -f d"
  system(cmd) || raise("#{cmd} failed")
end

task :default => :rspec

spec = Gem::Specification.find_by_name 'releasinator'
load "#{spec.gem_dir}/lib/tasks/releasinator.rake"