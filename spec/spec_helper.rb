require 'bundler/setup'
Bundler.setup(:default, :development, :test)

require 'coveralls'
Coveralls.wear!

require 'sequel'
require 'faker'
require File.expand_path(File.dirname(__FILE__) + '/../lib/sequel/extensions/seed.rb')

RSpec.configure do |config|
  Sequel.extension :seed

  class Sequel::Seeder
    def self.seeder_class(directory)
      if self.equal?(Sequel::Seeder)
        return Sequel::TimestampSeeder
      else
        self
      end
    end
  end

  class Sequel::TimestampSeeder
    def run
      seed_tuples.each {|s| s.apply}
      Sequel::Seed.descendants.clear
    end

    private

    def get_applied_seeds
      []
    end

    def get_seed_files
      []
    end

    def get_seed_tuples
      Sequel::Seed.descendants
    end
  end

  DB = Sequel.sqlite

  DB.create_table(:spec_models) do
    primary_key :id, :auto_increment => true
    String :name
  end

  config.before(:each) do
    SpecModel.dataset.delete
    Sequel::Seed.descendants.clear
  end
end

class SpecModel < Sequel::Model
end
