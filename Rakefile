require 'rake'
require_relative 'version'

GEM = 'sequel-seed'
VERSION = Sequel::Seed::VERSION

desc 'Build the sequel-seed gem'
task :build do |p|
  sh %{#{FileUtils::RUBY} -S gem build #{GEM}.gemspec}
end

desc 'Release the sequel-seed gem to rubygems.org'
task release: :build do
  sh %{#{FileUtils::RUBY} -S gem push ./#{GEM}-#{VERSION}.gem}
end

desc 'Run the specs for the sequel-seed'
task :test do
  sh %{#{FileUtils::RUBY} -S bundle exec rspec}
end
