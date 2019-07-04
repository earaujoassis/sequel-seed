# frozen_string_literal: true

require "bundler/setup"
Bundler.setup(:default, :test)

require "simplecov"
SimpleCov.start

require "codecov"
SimpleCov.formatter = SimpleCov::Formatter::Codecov

require "sequel"
require File.expand_path(File.dirname(__FILE__) + "/../lib/sequel/extensions/seed.rb")

require "faker"

module Sequel::Seed
  module TestHelper
    def seed_test_dir
      @test_dir ||= ENV["TEST_PATH"] || "./.testing"
    end

    def seed_file_name
      "#{Time.now.strftime("%Y%m%d%H%M%S")}_testing_#{Faker::Lorem.word}_#{Faker::Lorem.word}"
    end
  end
end

RSpec.configure do |config|
  include Sequel::Seed::TestHelper

  config.before(:suite) do
    puts "Sequel.version => #{Sequel.version}"
    FileUtils.mkdir_p(seed_test_dir)
  end

  config.before(:each) do
    # QUICK FIX:
    # Somehow the dataset models are not excluded fast enough
    sleep(0.750)
  end

  config.after(:all) do
    # It clears the `seed_test_dir` folder after each spec
    FileUtils.rm_rf("#{seed_test_dir}/.", secure: true)
  end

  config.after(:suite) do
    FileUtils.remove_dir(seed_test_dir, true)
  end
end
