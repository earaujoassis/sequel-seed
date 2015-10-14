require 'date'
require File.expand_path(File.dirname(__FILE__) + '/version.rb')

SEQUEL_SEED_GEMSPEC = Gem::Specification.new do |s|
  s.name                  = 'sequel-seed'
  s.date                  = Date.today.strftime('%Y-%m-%d')
  s.version               = Sequel::Seed::VERSION
  s.platform              = Gem::Platform::RUBY
  s.has_rdoc              = true
  s.summary               = "A Sequel extension to make seeds/fixtures manageable like migrations"
  s.description           = s.summary
  s.author                = "Ewerton Assis"
  s.email                 = "earaujoassis@gmail.com"
  s.homepage              = "https://github.com/earaujoassis/sequel-seed"
  s.license               = 'MIT'
  s.required_ruby_version = ">= 1.9.3"
  s.files                 = %w(LICENSE CHANGELOG.md README.md) + Dir["{spec,lib}/**/*.{rb,RB}"]
  s.require_path          = 'lib'

  s.add_runtime_dependency 'sequel', '>= 4.0'
end
