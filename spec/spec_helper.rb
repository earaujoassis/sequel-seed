require 'bundler/setup'
Bundler.setup(:default, :development, :test)

require 'coveralls'
Coveralls.wear!

require 'sequel'
require File.expand_path(File.dirname(__FILE__) + '/../lib/sequel/extensions/seed.rb')

require 'faker'

module Sequel::Seed
  module TestHelper
    def seed_test_dir
      @test_dir ||= ENV['TEST_PATH'] || './.testing'
    end

    def seed_file_name
      "#{Time.now.strftime('%Y%m%d%H%M%S')}_testing_#{Faker::Lorem.word}_#{Faker::Lorem.word}"
    end
  end
end

RSpec.configure do |config|
  include Sequel::Seed::TestHelper

  Sequel.extension :seed

  dsn = if RUBY_PLATFORM == 'java'
    'jdbc:sqlite::memory:'
  else
    'sqlite:/'
  end

  DB = Sequel.connect(dsn)

  DB.create_table(:spec_models) do
    primary_key :id, :auto_increment => true
    String :sentence
  end

  config.before(:suite) do
    FileUtils.mkdir_p(seed_test_dir)
  end

  config.before(:each) do
    SpecModel.dataset.delete
    Sequel::Seed::Base.descendants.clear
    # QUICK FIX: Somehow the dataset models are not excluded fast enough
    sleep(0.750)
  end

  config.after(:suite) do
    FileUtils.remove_dir(seed_test_dir, true)
  end
end

class SpecModel < Sequel::Model
end
