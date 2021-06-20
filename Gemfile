# frozen_string_literal: true

source "https://rubygems.org"

gem "rake"
gem "sequel", ">= 4.49.0"

group :development do
  gem "jekyll", require: false, platform: :mri
end

group :development, :test do
  gem "codecov", require: false
  gem "faker"
  gem "jdbc-postgres", platform: :jruby
  gem "jdbc-sqlite3", platform: :jruby
  gem "pg", platform: :mri
  gem "rspec"
  gem "rubocop", require: false
  gem "rubocop-github", require: false
  gem "sqlite3", platform: :mri
end
