require 'rake'
require File.expand_path(File.dirname(__FILE__) + '/version.rb')

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

namespace :db do
  desc 'Create the database'
  task :create do
    sh %{createdb sequel_seed_test}
  end

  desc 'Destroy the database'
  task :destroy do
    sh %{dropdb sequel_seed_test}
  end
end

task localtest: ['db:create', :test, 'db:destroy']
task default: [:test, :build]
