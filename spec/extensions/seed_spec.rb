require 'spec_helper'

describe Sequel.seed do
  before do
    Sequel::Seed.setup(:test)
  end

  it 'should create a Seed descendant according to the current environment' do
    seed = Sequel.seed(:test) {}
    expect(Sequel::Seed::Base.descendants).to include seed
  end

  it 'should ignore a Seed not applicable to the current environment' do
    seed = Sequel.seed(:development) {}
    expect(Sequel::Seed::Base.descendants).not_to include seed
  end

  it 'should create a Seed applicable to every environment' do
    seed = Sequel.seed {}
    expect(Sequel::Seed::Base.descendants).to include seed
  end
end

describe Sequel::Seed.environment do
  it 'should be possible to set the environment with Sequel::Seed.setup method' do
    Sequel::Seed.setup(:mock)
    expect(Sequel::Seed.environment).to eq :mock
    Sequel::Seed.setup("test")
    expect(Sequel::Seed.environment).to eq :test
  end

  it 'should be possible to set the environment with Sequel::Seed.environment= method' do
    Sequel::Seed.environment = :mock
    expect(Sequel::Seed.environment).to eq :mock
    Sequel::Seed.environment = "test"
    expect(Sequel::Seed.environment).to eq :test
  end
end

describe Sequel::Seed do
  describe "to guarantee backward compatibility" do
    it "should point Sequel::Seed.descendants to Sequel::Seed::Base.descendants" do
      Sequel::Seed::Base.descendants << 'hi'
      expect(Sequel::Seed.descendants).to contain_exactly('hi')
    end

    it "should point Sequel::Seed.inherited() to Sequel::Seed::Base.inherited()" do
      Sequel::Seed::Base.inherited('1')
      Sequel::Seed.inherited('2')
      expect(Sequel::Seed.descendants).to contain_exactly('1', '2')
    end
  end
end

describe Sequel::Seeder do
  let(:DB) {Sequel.sqlite}
  let!(:environment) {"#{Faker::Lorem.word}_#{Faker::Lorem.word}"}

  it "should raise an error when there is not any seed file to apply" do
    Sequel::Seed.setup environment

    expect(Sequel::Seed::Base.descendants.length).to be 0
    expect {Sequel::Seeder.apply(DB, '/')}.to raise_error("seeder not available for files; please checked the directory")
    expect(SpecModel.dataset.all.length).to be 0
  end

  describe 'environment references should be indistinguishable between Symbol and String' do
    context 'when the environment is defined using a String' do
      it 'should apply the Seed accordingly' do
        Sequel::Seed.setup environment

        File.open("#{seed_test_dir}/#{seed_file_name}", 'w+') do |f|
          f.puts "Sequel.seed(:#{environment}) do"
          f.puts '  def run'
          f.puts '    SpecModel.create :sentence => \'environment defined by String\''
          f.puts '  end'
          f.puts 'end'
        end

        expect(Sequel::Seed::Base.descendants.length).to be 0
        expect(Sequel::Seeder.seeder_class(seed_test_dir)).to be Sequel::TimestampSeeder
        expect {Sequel::Seeder.apply(DB, seed_test_dir)}.not_to raise_error
        expect(Sequel::Seed::Base.descendants.length).to be 1
        expect(SpecModel.dataset.all.length).to be 1
        expect(SpecModel.dataset.first.sentence).to eq 'environment defined by String'
      end
    end

    context 'when the Seed is defined using a String' do
      it 'should apply the Seed accordingly' do
        Sequel::Seed.setup environment.to_sym

        File.open("#{seed_test_dir}/#{seed_file_name}", 'w+') do |f|
          f.puts "Sequel.seed(\"#{environment}\") do"
          f.puts '  def run'
          f.puts '    SpecModel.create :sentence => \'Seed defined by String\''
          f.puts '  end'
          f.puts 'end'
        end

        expect(Sequel::Seed::Base.descendants.length).to be 0
        expect {Sequel::Seeder.apply(DB, seed_test_dir)}.not_to raise_error
        expect(Sequel::Seed::Base.descendants.length).to be 1
        expect(SpecModel.dataset.all.length).to be 1
        expect(SpecModel.dataset.first.sentence).to eq 'Seed defined by String'
      end
    end

    context 'when both Seed and environment are defined using a String' do
      it 'should apply the Seed accordingly' do
        Sequel::Seed.setup environment

        File.open("#{seed_test_dir}/#{seed_file_name}", 'w+') do |f|
          f.puts "Sequel.seed(\"#{environment}\") do"
          f.puts '  def run'
          f.puts '    SpecModel.create :sentence => \'Seed and environment defined by String\''
          f.puts '  end'
          f.puts 'end'
        end

        expect(Sequel::Seed::Base.descendants.length).to be 0
        expect {Sequel::Seeder.apply(DB, seed_test_dir)}.not_to raise_error
        expect(Sequel::Seed::Base.descendants.length).to be 1
        expect(SpecModel.dataset.all.length).to be 1
        expect(SpecModel.dataset.first.sentence).to eq 'Seed and environment defined by String'
      end
    end

    context 'when both Seed and environment are defined using a Symbol' do
      it 'should apply the Seed accordingly' do
        Sequel::Seed.setup environment.to_sym

        File.open("#{seed_test_dir}/#{seed_file_name}", 'w+') do |f|
          f.puts "Sequel.seed(:#{environment}) do"
          f.puts '  def run'
          f.puts '    SpecModel.create :sentence => \'Seed and environment defined by Symbol\''
          f.puts '  end'
          f.puts 'end'
        end

        expect(Sequel::Seed::Base.descendants.length).to be 0
        expect {Sequel::Seeder.apply(DB, seed_test_dir)}.not_to raise_error
        expect(Sequel::Seed::Base.descendants.length).to be 1
        expect(SpecModel.dataset.all.length).to be 1
        expect(SpecModel.dataset.first.sentence).to eq 'Seed and environment defined by Symbol'
      end
    end

    context 'when the environment is defined using a String and we have a wildcard Seed' do
      it 'should apply the Seed accordingly' do
        Sequel::Seed.setup environment

        File.open("#{seed_test_dir}/#{seed_file_name}", 'w+') do |f|
          f.puts 'Sequel.seed do'
          f.puts '  def run'
          f.puts '    SpecModel.create :sentence => \'Wildcard Seed and environment defined by String\''
          f.puts '  end'
          f.puts 'end'
        end

        expect(Sequel::Seed::Base.descendants.length).to be 0
        expect {Sequel::Seeder.apply(DB, seed_test_dir)}.not_to raise_error
        expect(Sequel::Seed::Base.descendants.length).to be 1
        expect(SpecModel.dataset.all.length).to be 1
        expect(SpecModel.dataset.first.sentence).to eq 'Wildcard Seed and environment defined by String'
      end
    end
  end

  context 'when there\'s a Seed created' do
    it 'should change the database accordingly only once' do
      Sequel::Seed.setup environment

      File.open("#{seed_test_dir}/#{seed_file_name}", 'w+') do |f|
        f.puts 'Sequel.seed do'
        f.puts '  def run'
        f.puts '    SpecModel.create :sentence => \'should have changed\''
        f.puts '  end'
        f.puts 'end'
      end

      expect(Sequel::Seed::Base.descendants.length).to be 0
      expect {Sequel::Seeder.apply(DB, seed_test_dir)}.not_to raise_error
      expect(Sequel::Seed::Base.descendants.length).to be 1
      expect(SpecModel.dataset.all.length).to be 1
      expect(SpecModel.dataset.first.sentence).to eq 'should have changed'
      # Once again
      expect {Sequel::Seeder.apply(DB, seed_test_dir)}.not_to raise_error
      expect(Sequel::Seed::Base.descendants.length).to be 0
      expect(SpecModel.dataset.all.length).to be 1
      expect(SpecModel.dataset.first.sentence).to eq 'should have changed'
    end
  end

  context 'when the specified Seed is not applicable to the current environment' do
    it 'should not make any change to the database' do
      Sequel::Seed.setup environment

      File.open("#{seed_test_dir}/#{seed_file_name}", 'w+') do |f|
        f.puts "Sequel.seed(:another_#{Faker::Lorem.word}_word) do"
        f.puts '  def run'
        f.puts '    SpecModel.create :sentence => \'should have changed\''
        f.puts '  end'
        f.puts 'end'
      end

      expect(Sequel::Seed::Base.descendants.length).to be 0
      expect {Sequel::Seeder.apply(DB, seed_test_dir)}.not_to raise_error
      expect(SpecModel.dataset.all.length).to be 0
    end
  end
end
