# frozen_string_literal: true

require "spec_helper"

describe Sequel::Seeder do
  let!(:environment) { "#{Faker::Lorem.word}_#{Faker::Lorem.word}" }
  let!(:random_word) { Faker::Lorem.word }

  before do
    Sequel.extension :seed
    Sequel.extension :pg_array
    ArraySpecModel.dataset.delete
    Sequel::Seed::Base.descendants.clear
  end

  before(:all) do
    dsn = begin
      if RUBY_PLATFORM == "java"
        "jdbc:postgresql://localhost/sequel_seed_test"
      else
        "postgres://localhost/sequel_seed_test"
      end
    end
    @db = Sequel.connect(dsn)
    @db.extension(:pg_array)
    @db.drop_table?(:array_spec_models)
    @db.create_table(:array_spec_models) do
      primary_key :id, :serial
      column :selectors, "text[]"
      String :sentence
    end
    class ArraySpecModel < Sequel::Model(@db); end
    ArraySpecModel.dataset = @db[:array_spec_models]
    #Sequel::Model.db = @db
  end

  after(:each) do
    ArraySpecModel.dataset.delete
    Sequel::Seed::Base.descendants.clear
  end

  it "should raise an error when there is not any seed file to apply" do
    Sequel::Seed.setup environment

    expect(Sequel::Seed::Base.descendants.length).to be 0
    expect { Sequel::Seeder.apply(@db, "/") }.to raise_error("seeder not available for files; please check the configured seed directory \"/\". Also ensure seed files are in YYYYMMDD_seed_file.rb format.")
    expect(ArraySpecModel.dataset.all.length).to be 0
  end

  describe "Seeds defined using Ruby code (.rb extension)" do
    describe "environment references should be indistinguishable between Symbol and String" do
      context "when the environment is defined using a String" do
        it "should apply the Seed accordingly" do
          Sequel::Seed.setup environment

          File.open("#{seed_test_dir}/#{seed_file_name}.rb", "w+") do |f|
            f.puts "Sequel.seed(:#{environment}) do"
            f.puts "  def run"
            f.puts "    ArraySpecModel.create \\"
            f.puts "      :sentence => \"environment defined by String\","
            f.puts "      :selectors => [\".body\", \".header\", \".string\"]"
            f.puts "  end"
            f.puts "end"
          end

          expect(Sequel::Seed::Base.descendants.length).to be 0
          expect(Sequel::Seeder.seeder_class(seed_test_dir)).to be Sequel::TimestampSeeder
          expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
          expect(Sequel::Seed::Base.descendants.length).to be 1
          expect(ArraySpecModel.dataset.all.length).to be 1
          expect(ArraySpecModel.dataset.first.sentence).to eq "environment defined by String"
          expect(ArraySpecModel.dataset.first.selectors).to contain_exactly(".body", ".header", ".string")
        end
      end

      context "when the Seed is defined using a String" do
        it "should apply the Seed accordingly" do
          Sequel::Seed.setup environment.to_sym

          File.open("#{seed_test_dir}/#{seed_file_name}.rb", "w+") do |f|
            f.puts "Sequel.seed(\"#{environment}\") do"
            f.puts "  def run"
            f.puts "    ArraySpecModel.create \\"
            f.puts "      :sentence => \"Seed defined by String\","
            f.puts "      :selectors => [\".body\", \".header\", \".environment\"]"
            f.puts "  end"
            f.puts "end"
          end

          expect(Sequel::Seed::Base.descendants.length).to be 0
          expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
          expect(Sequel::Seed::Base.descendants.length).to be 1
          expect(ArraySpecModel.dataset.all.length).to be 1
          expect(ArraySpecModel.dataset.first.sentence).to eq "Seed defined by String"
          expect(ArraySpecModel.dataset.first.selectors).to contain_exactly(".body", ".header", ".environment")
        end
      end

      context "when both Seed and environment are defined using a String" do
        it "should apply the Seed accordingly" do
          Sequel::Seed.setup environment

          File.open("#{seed_test_dir}/#{seed_file_name}.rb", "w+") do |f|
            f.puts "Sequel.seed(\"#{environment}\") do"
            f.puts "  def run"
            f.puts "    ArraySpecModel.create \\"
            f.puts "      :sentence => \"Seed and environment defined by String\","
            f.puts "      :selectors => [\".body\", \".header\", \".string\", \".environment\"]"
            f.puts "  end"
            f.puts "end"
          end

          expect(Sequel::Seed::Base.descendants.length).to be 0
          expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
          expect(Sequel::Seed::Base.descendants.length).to be 1
          expect(ArraySpecModel.dataset.all.length).to be 1
          expect(ArraySpecModel.dataset.first.sentence).to eq "Seed and environment defined by String"
          expect(ArraySpecModel.dataset.first.selectors).to contain_exactly(".body", ".header", ".string", ".environment")
        end
      end

      context "when both Seed and environment are defined using a Symbol" do
        it "should apply the Seed accordingly" do
          Sequel::Seed.setup environment.to_sym

          File.open("#{seed_test_dir}/#{seed_file_name}.rb", "w+") do |f|
            f.puts "Sequel.seed(:#{environment}) do"
            f.puts "  def run"
            f.puts "    ArraySpecModel.create \\"
            f.puts "      :sentence => \"Seed and environment defined by Symbol\","
            f.puts "      :selectors => [\".body\", \".header\", \".string\", \".environment\", \".symbol\"]"
            f.puts "  end"
            f.puts "end"
          end

          expect(Sequel::Seed::Base.descendants.length).to be 0
          expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
          expect(Sequel::Seed::Base.descendants.length).to be 1
          expect(ArraySpecModel.dataset.all.length).to be 1
          expect(ArraySpecModel.dataset.first.sentence).to eq "Seed and environment defined by Symbol"
          expect(ArraySpecModel.dataset.first.selectors).to contain_exactly(".body", ".header", ".string", ".environment", ".symbol")
        end
      end

      context "when the environment is defined using a String and we have a wildcard Seed" do
        it "should apply the Seed accordingly" do
          Sequel::Seed.setup environment

          File.open("#{seed_test_dir}/#{seed_file_name}.rb", "w+") do |f|
            f.puts "Sequel.seed do"
            f.puts "  def run"
            f.puts "    ArraySpecModel.create \\"
            f.puts "      :sentence => \"Wildcard Seed and environment defined by String\","
            f.puts "      :selectors => [\".body\", \".header\", \".string\", \".wildcard\"]"
            f.puts "  end"
            f.puts "end"
          end

          expect(Sequel::Seed::Base.descendants.length).to be 0
          expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
          expect(Sequel::Seed::Base.descendants.length).to be 1
          expect(ArraySpecModel.dataset.all.length).to be 1
          expect(ArraySpecModel.dataset.first.sentence).to eq "Wildcard Seed and environment defined by String"
          expect(ArraySpecModel.dataset.first.selectors).to contain_exactly(".body", ".header", ".string", ".wildcard")
        end
      end
    end

    context "when there\"s a Seed created" do
      it "should change the database accordingly only once" do
        Sequel::Seed.setup environment

        File.open("#{seed_test_dir}/#{seed_file_name}.rb", "w+") do |f|
          f.puts "Sequel.seed do"
          f.puts "  def run"
          f.puts "    ArraySpecModel.create \\"
          f.puts "      :sentence => \"should have changed (from Ruby file)\","
          f.puts "      :selectors => [\".body\", \".header\", \".string\", \".ruby\"]"
          f.puts "  end"
          f.puts "end"
        end

        expect(Sequel::Seed::Base.descendants.length).to be 0
        expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
        expect(Sequel::Seed::Base.descendants.length).to be 1
        expect(ArraySpecModel.dataset.all.length).to be 1
        expect(ArraySpecModel.dataset.first.sentence).to eq "should have changed (from Ruby file)"
        expect(ArraySpecModel.dataset.first.selectors).to contain_exactly(".body", ".header", ".string", ".ruby")
        # Once again
        expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
        expect(Sequel::Seed::Base.descendants.length).to be 0
        expect(ArraySpecModel.dataset.all.length).to be 1
        expect(ArraySpecModel.dataset.first.sentence).to eq "should have changed (from Ruby file)"
        expect(ArraySpecModel.dataset.first.selectors).to contain_exactly(".body", ".header", ".string", ".ruby")
      end
    end

    context "when the specified Seed is not applicable to the given environment" do
      it "should not make any change to the database" do
        Sequel::Seed.setup environment

        File.open("#{seed_test_dir}/#{seed_file_name}.rb", "w+") do |f|
          f.puts "Sequel.seed(:another_#{Faker::Lorem.word}_word) do"
          f.puts "  def run"
          f.puts "    ArraySpecModel.create \\"
          f.puts "      :sentence => \"should not have changed (from Ruby file)\","
          f.puts "      :selectors => [\".body\", \".header\", \".unchanged\", \".ruby\"]"
          f.puts "  end"
          f.puts "end"
        end

        expect(Sequel::Seed::Base.descendants.length).to be 0
        expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
        expect(ArraySpecModel.dataset.all.length).to be 0
      end
    end
  end

  describe "Seeds defined using YAML code (.{yaml,yml} extension)" do
    it "should apply a basic YAML Seed if it was specified for the given environment" do
      Sequel::Seed.setup environment

      File.open("#{seed_test_dir}/#{seed_file_name}.yml", "w+") do |f|
        f.puts "environment: :#{environment}"
        f.puts "array_spec_model:"
        f.puts "  sentence: \"should have changed (from YAML file) #{random_word}\""
        f.puts "  selectors:"
        f.puts "    - \".body\""
        f.puts "    - \".header\""
        f.puts "    - \".yaml\""
        f.puts ""
      end

      expect(Sequel::Seed::Base.descendants.length).to be 0
      expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
      expect(Sequel::Seed::Base.descendants.length).to be 1
      expect(ArraySpecModel.dataset.all.length).to be 1
      expect(ArraySpecModel.dataset.first.sentence).to eq "should have changed (from YAML file) #{random_word}"
      expect(ArraySpecModel.dataset.first.selectors).to contain_exactly(".body", ".header", ".yaml")
    end

    it "should apply a YAML Seed if it was specified for the given environment" do
      Sequel::Seed.setup environment

      File.open("#{seed_test_dir}/#{seed_file_name}.yml", "w+") do |f|
        f.puts "environment: :#{environment}"
        f.puts "model:"
        f.puts "  class: \"ArraySpecModel\""
        f.puts "  entries:"
        f.puts "    -"
        f.puts "      sentence: \"should have changed (from YAML file) #{random_word}\""
        f.puts "      selectors:"
        f.puts "        - .body"
        f.puts "        - .header"
        f.puts "        - .yaml"
        f.puts ""
      end

      expect(Sequel::Seed::Base.descendants.length).to be 0
      expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
      expect(Sequel::Seed::Base.descendants.length).to be 1
      expect(ArraySpecModel.dataset.all.length).to be 1
      expect(ArraySpecModel.dataset.first.sentence).to eq "should have changed (from YAML file) #{random_word}"
      expect(ArraySpecModel.dataset.first.selectors).to contain_exactly(".body", ".header", ".yaml")
    end

    it "should apply a YAML file with multiple Seeds descriptors if they were specified for the given environment" do
      Sequel::Seed.setup environment

      File.open("#{seed_test_dir}/#{seed_file_name}.yml", "w+") do |f|
        f.puts "-"
        f.puts "  environment: :#{environment}"
        f.puts "  model:"
        f.puts "    class: \"ArraySpecModel\""
        f.puts "    entries:"
        f.puts "      -"
        f.puts "        sentence: \"should have changed (from YAML file) #{random_word}\""
        f.puts "        selectors:"
        f.puts "          - .body"
        f.puts "          - .header"
        f.puts "          - .yaml"
        f.puts "          - .environment"
        f.puts "-"
        f.puts "  environment: :another_#{environment}"
        f.puts "  array_spec_model:"
        f.puts "    sentence: \"should not have changed (from YAML file) #{random_word}\""
        f.puts "    selectors:"
        f.puts "      - .body"
        f.puts "      - .header"
        f.puts "      - .yaml"
        f.puts "      - .another_environment"
        f.puts ""
      end

      expect(Sequel::Seed::Base.descendants.length).to be 0
      expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
      expect(Sequel::Seed::Base.descendants.length).to be 1
      expect(ArraySpecModel.dataset.all.length).to be 1
      expect(ArraySpecModel.dataset.first.sentence).to eq "should have changed (from YAML file) #{random_word}"
      expect(ArraySpecModel.dataset.first.selectors).to contain_exactly(".body", ".header", ".yaml", ".environment")
    end

    it "should not apply a basic Seed if it was not specified for the given environment" do
      Sequel::Seed.setup environment

      File.open("#{seed_test_dir}/#{seed_file_name}.yml", "w+") do |f|
        f.puts "environment: :another_environment_#{Faker::Lorem.word}"
        f.puts "array_spec_model:"
        f.puts "  sentence: \"should not have changed (from YAML file)\""
        f.puts "  selectors:"
        f.puts "    - .body"
        f.puts "    - .header"
        f.puts "    - .yaml"
        f.puts ""
      end

      expect(Sequel::Seed::Base.descendants.length).to be 0
      expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
      expect(Sequel::Seed::Base.descendants.length).to be 1
      expect(ArraySpecModel.dataset.all.length).to be 0
    end
  end

  describe "Seeds defined using JSON code (.json extension)" do
    it "should apply a basic JSON Seed if it was specified for the given environment" do
      Sequel::Seed.setup environment

      File.open("#{seed_test_dir}/#{seed_file_name}.json", "w+") do |f|
        f.puts "{"
        f.puts "  \"environment\": \"#{environment}\","
        f.puts "  \"array_spec_model\": {"
        f.puts "    \"sentence\": \"should have changed (from JSON file) #{random_word}\","
        f.puts "    \"selectors\": [\".body\", \".header\", \".json\"]"
        f.puts "  }"
        f.puts "}"
        f.puts ""
      end

      expect(Sequel::Seed::Base.descendants.length).to be 0
      expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
      expect(Sequel::Seed::Base.descendants.length).to be 1
      expect(ArraySpecModel.dataset.all.length).to be 1
      expect(ArraySpecModel.dataset.first.sentence).to eq "should have changed (from JSON file) #{random_word}"
      expect(ArraySpecModel.dataset.first.selectors).to contain_exactly(".body", ".header", ".json")
    end

    it "should apply a JSON Seed if it was specified for the given environment" do
      Sequel::Seed.setup environment

      File.open("#{seed_test_dir}/#{seed_file_name}.json", "w+") do |f|
        f.puts "{"
        f.puts "  \"environment\": \"#{environment}\","
        f.puts "  \"model\": {"
        f.puts "    \"class\": \"ArraySpecModel\","
        f.puts "    \"entries\": ["
        f.puts "      {"
        f.puts "        \"sentence\": \"should have changed (from JSON file) #{random_word}\","
        f.puts "        \"selectors\": [\".body\", \".header\", \".json\"]"
        f.puts "      }"
        f.puts "    ]"
        f.puts "  }"
        f.puts "}"
        f.puts ""
      end

      expect(Sequel::Seed::Base.descendants.length).to be 0
      expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
      expect(Sequel::Seed::Base.descendants.length).to be 1
      expect(ArraySpecModel.dataset.all.length).to be 1
      expect(ArraySpecModel.dataset.first.sentence).to eq "should have changed (from JSON file) #{random_word}"
      expect(ArraySpecModel.dataset.first.selectors).to contain_exactly(".body", ".header", ".json")
    end

    it "should apply a JSON file with multiple Seeds descriptors if they were specified for the given environment" do
      Sequel::Seed.setup environment

      File.open("#{seed_test_dir}/#{seed_file_name}.json", "w+") do |f|
        f.puts "["
        f.puts "  {"
        f.puts "    \"environment\": \"#{environment}\","
        f.puts "    \"model\": {"
        f.puts "      \"class\": \"ArraySpecModel\","
        f.puts "      \"entries\": ["
        f.puts "        {"
        f.puts "          \"sentence\": \"should have changed (from JSON file) #{random_word}\","
        f.puts "          \"selectors\": [\".body\", \".header\", \".json\", \".environment\"]"
        f.puts "        }"
        f.puts "      ]"
        f.puts "    }"
        f.puts "  },"
        f.puts "  {"
        f.puts "    \"environment\": \"another_#{environment}\","
        f.puts "    \"model\": {"
        f.puts "      \"class\": \"ArraySpecModel\","
        f.puts "      \"entries\": ["
        f.puts "        {"
        f.puts "          \"sentence\": \"should have changed (from JSON file) #{random_word}\","
        f.puts "          \"selectors\": [\".body\", \".header\", \".json\", \".another_environment\"]"
        f.puts "        }"
        f.puts "      ]"
        f.puts "    }"
        f.puts "  }"
        f.puts "]"
        f.puts ""
      end

      expect(Sequel::Seed::Base.descendants.length).to be 0
      expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
      expect(Sequel::Seed::Base.descendants.length).to be 1
      expect(ArraySpecModel.dataset.all.length).to be 1
      expect(ArraySpecModel.dataset.first.sentence).to eq "should have changed (from JSON file) #{random_word}"
      expect(ArraySpecModel.dataset.first.selectors).to contain_exactly(".body", ".header", ".json", ".environment")
    end

    it "should not apply a basic Seed if it was not specified for the given environment" do
      Sequel::Seed.setup environment

      File.open("#{seed_test_dir}/#{seed_file_name}.json", "w+") do |f|
        f.puts "{"
        f.puts "  \"environment\": \"another_#{environment}\","
        f.puts "  \"array_spec_model\": {"
        f.puts "    \"sentence\": \"should not changed (from JSON file) #{random_word}\","
        f.puts "    \"selectors\": [\".body\", \".header\", \".json\"]"
        f.puts "  }"
        f.puts "}"
        f.puts ""
      end

      expect(Sequel::Seed::Base.descendants.length).to be 0
      expect { Sequel::Seeder.apply(@db, seed_test_dir) }.not_to raise_error
      expect(Sequel::Seed::Base.descendants.length).to be 1
      expect(ArraySpecModel.dataset.all.length).to be 0
    end
  end
end
