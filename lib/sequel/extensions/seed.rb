require 'yaml'
require 'json'

##
# Extension based upon Sequel::Migration and Sequel::Migrator
#
# Adds the Sequel::Seed module and the Sequel::Seed::Base and Sequel::Seeder
# classes, which allow the user to easily group entity changes and seed/fixture
# the database to a newer version only (unlike migrations, seeds are not
# directional).
#
# To load the extension:
#
#   Sequel.extension :seed
#
# It is also important to set the environment:
#
#   Sequel::Seed.setup(:development)

module Sequel
  class << self
    ##
    # Creates a Seed subclass according to the given +block+.
    #
    # The +env_labels+ lists on which environments the seed should be applicable.
    # If the current environment is not applicable, the seed is ignored. On the
    # other hand, if it is applicable, it will be listed in Seed.descendants and
    # subject to application (if it was not applied yet).
    #
    # Expected seed call:
    #
    #   Sequel.seed(:test) do # seed is only applicable to the test environment
    #     def run
    #       Entity.create attribute: value
    #     end
    #   end
    #
    # Wildcard seed:
    #
    #   Sequel.seed do # seed is applicable to every environment, or no environment
    #     def run
    #       Entity.create attribute: value
    #     end
    #   end
    #

    def seed *env_labels, &block
      return if env_labels.length > 0 && !env_labels.map(&:to_sym).include?(Seed.environment)

      seed = Class.new(Seed::Base)
      seed.class_eval(&block) if block_given?
      Seed::Base.inherited(seed) unless Seed::Base.descendants.include?(seed)
      seed
    end
  end

  module Seed
    class Error < Sequel::Error
    end

    class << self
      attr_reader :environment

      ##
      # Sets the Sequel::Seed's environment to +env+ over which the Seeds should be applied
      def setup(env, opts = {})
        @environment = env.to_sym
        @options ||= {}
        @options[:disable_warning] ||= opts[:disable_warning] || false
      end

      ##
      # Keep backward compatibility on how to setup the Sequel::Seed environment
      #
      # Sets the environment +env+ over which the Seeds should be applied
      def environment=(env)
        setup(env)
      end

      ##
      # Keep backward compatibility on how to get Sequel::Seed::Base class descendants
      def descendants
        Base.descendants
      end

      ##
      # Keep backward compatibility on how to append a Sequel::Seed::Base descendant class
      def inherited(base)
        Base.inherited(base)
      end
    end

    ##
    # Helper methods for the Sequel::Seed project.

    module Helpers
      class << self
        def camelize(term, uppercase_first_letter = true)
          string = term.to_s
          if uppercase_first_letter
            string.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
          else
            string.first + camelize(string)[1..-1]
          end
        end
      end
    end

    module SeedDescriptor
      def apply_seed_descriptor(seed_descriptor)
        case seed_descriptor
        when Hash
          apply_seed_hash(seed_descriptor)
        when Array
          seed_descriptor.each {|seed_hash| apply_seed_hash(seed_hash)}
        end
      end

      private

      def apply_seed_hash(seed_hash)
        return unless seed_hash.class <= Hash
        if seed_hash.has_key?('environment')
          case seed_hash['environment']
          when String, Symbol
            return if seed_hash['environment'].to_sym != Seed.environment
          when Array
            return unless seed_hash['environment'].map(&:to_sym).include?(Seed.environment)
          end
        end

        keys = seed_hash.keys
        keys.delete('environment')
        keys.each do |key|
          key_hash = seed_hash[key]
          entries = nil
          class_name = if key_hash.has_key?('class')
            entries = key_hash['entries']
            key_hash['class']
          else
            Helpers.camelize(key)
          end
          # It will raise an error if the class name is not defined
          class_const = Kernel.const_get(class_name)
          if entries
            entries.each {|hash| create_model(class_const, hash)}
          else
            create_model(class_const, key_hash)
          end
        end
      end

      def create_model(class_const, hash)
        object_instance = class_const.new
        object_instance_attr = hash.each do |attr, value|
          object_instance.set({attr.to_sym => value})
        end
        raise(Error, "Attempt to create invalid model instance of #{class_name}") unless object_instance.valid?
        object_instance.save
      end
    end

    class Base
      class << self
        def apply
          new.run
        end

        def descendants
          @descendants ||= []
        end

        def inherited(base)
          descendants << base
        end
      end

      def run
      end
    end

    ##
    # Class resposible for applying all the seeds related to the current environment,
    # if and only if they were not previously applied.
    #
    # To apply the seeds/fixtures:
    #
    #   Sequel::Seeder.apply(db, directory)
    #
    # +db+ holds the Sequel database connection
    #
    # +directory+ the path to the seeds/fixtures files
  end

  class Seeder
    SEED_FILE_PATTERN = /\A(\d+)_.+\.(rb|json|yml|yaml)\z/i.freeze
    RUBY_SEED_FILE_PATTERN = /\A(\d+)_.+\.(rb)\z/i.freeze
    YAML_SEED_FILE_PATTERN = /\A(\d+)_.+\.(yml|yaml)\z/i.freeze
    JSON_SEED_FILE_PATTERN = /\A(\d+)_.+\.(json)\z/i.freeze
    SEED_SPLITTER = '_'.freeze
    MINIMUM_TIMESTAMP = 20000101

    Error = Seed::Error

    def self.apply(db, directory, opts = {})
      seeder_class(directory).new(db, directory, opts).run
    end

    def self.seeder_class(directory)
      if self.equal?(Seeder)
        Dir.new(directory).each do |file|
          next unless SEED_FILE_PATTERN.match(file)
          return TimestampSeeder if file.split(SEED_SPLITTER, 2).first.to_i > MINIMUM_TIMESTAMP
        end
        raise(Error, "seeder not available for files; please checked the directory")
      else
        self
      end
    end

    attr_reader :column

    attr_reader :db

    attr_reader :directory

    attr_reader :ds

    attr_reader :files

    attr_reader :table

    def initialize(db, directory, opts = {})
      raise(Error, "Must supply a valid seed path") unless File.directory?(directory)
      @db = db
      @directory = directory
      @allow_missing_seed_files = opts[:allow_missing_seed_files]
      @files = get_seed_files
      schema, table = @db.send(:schema_and_table, opts[:table]  || self.class.const_get(:DEFAULT_SCHEMA_TABLE))
      @table = schema ? Sequel::SQL::QualifiedIdentifier.new(schema, table) : table
      @column = opts[:column] || self.class.const_get(:DEFAULT_SCHEMA_COLUMN)
      @ds = schema_dataset
      @use_transactions = opts[:use_transactions]
    end

    private

    def checked_transaction(seed, &block)
      use_trans = if @use_transactions.nil?
        @db.supports_transactional_ddl?
      else
        @use_transactions
      end

      if use_trans
        db.transaction(&block)
      else
        yield
      end
    end

    def remove_seed_classes
      Seed::Base.descendants.each do |c|
        Object.send(:remove_const, c.to_s) rescue nil
      end
      Seed::Base.descendants.clear
    end

    def seed_version_from_file(filename)
      filename.split(SEED_SPLITTER, 2).first.to_i
    end
  end

  ##
  # A Seeder subclass to apply timestamped seeds/fixtures files.
  # It follows the same syntax & semantics for the Seeder superclass.
  #
  # To apply the seeds/fixtures:
  #
  #   Sequel::TimestampSeeder.apply(db, directory)
  #
  # +db+ holds the Sequel database connection
  #
  # +directory+ the path to the seeds/fixtures files

  class TimestampSeeder < Seeder
    DEFAULT_SCHEMA_COLUMN = :filename
    DEFAULT_SCHEMA_TABLE = :schema_seeds

    Error = Seed::Error

    attr_reader :applied_seeds

    attr_reader :seed_tuples

    def initialize(db, directory, opts = {})
      super
      @applied_seeds = get_applied_seeds
      @seed_tuples = get_seed_tuples
    end

    def run
      seed_tuples.each do |s, f|
        t = Time.now
        db.log_info("Begin applying seed #{f}")
        checked_transaction(s) do
          s.apply
          fi = f.downcase
          ds.insert(column => fi)
        end
        db.log_info("Finished applying seed #{f}, took #{sprintf('%0.6f', Time.now - t)} seconds")
      end
      nil
    end

    private

    def get_applied_seeds
      am = ds.select_order_map(column)
      missing_seed_files = am - files.map{|f| File.basename(f).downcase}
      if missing_seed_files.length > 0 && !@allow_missing_seed_files
        raise(Error, "Applied seed files not in file system: #{missing_seed_files.join(', ')}")
      end
      am
    end

    def get_seed_files
      files = []
      Dir.new(directory).each do |file|
        next unless SEED_FILE_PATTERN.match(file)
        files << File.join(directory, file)
      end
      files.sort_by{|f| SEED_FILE_PATTERN.match(File.basename(f))[1].to_i}
    end

    def get_seed_tuples
      remove_seed_classes
      seeds = []
      ms = Seed::Base.descendants
      files.each do |path|
        f = File.basename(path)
        fi = f.downcase
        if !applied_seeds.include?(fi)
          #begin
          load(path) if RUBY_SEED_FILE_PATTERN.match(f)
          create_yaml_seed(path) if YAML_SEED_FILE_PATTERN.match(f)
          create_json_seed(path) if JSON_SEED_FILE_PATTERN.match(f)
          #rescue Exception => e
            #raise(Error, "error while processing seed file #{path}: #{e.inspect}")
          #end
          el = [ms.last, f]
          next if ms.last.nil?
          if ms.last < Seed::Base && !seeds.include?(el)
            seeds << el
          end
        end
      end
      seeds
    end

    def create_yaml_seed(path)
      seed_descriptor = YAML::load(File.open(path))
      seed = Class.new(Seed::Base)
      seed.const_set "YAML_SEED", seed_descriptor
      seed.class_eval do
        include Seed::SeedDescriptor

        def run
          seed_descriptor = self.class.const_get "YAML_SEED"
          raise(Error, "YAML seed improperly defined") if seed_descriptor.nil?
          self.apply_seed_descriptor(seed_descriptor)
        end
      end
      Seed::Base.inherited(seed) unless Seed::Base.descendants.include?(seed)
      seed
    end

    def create_json_seed(path)
      seed_descriptor = JSON.parse(File.read(path))
      seed = Class.new(Seed::Base)
      seed.const_set "JSON_SEED", seed_descriptor
      seed.class_eval do
        include Seed::SeedDescriptor

        def run
          seed_descriptor = self.class.const_get "JSON_SEED"
          raise(Error, "JSON seed improperly defined") if seed_descriptor.nil?
          self.apply_seed_descriptor(seed_descriptor)
        end
      end
      Seed::Base.inherited(seed) unless Seed::Base.descendants.include?(seed)
      seed
    end

    def schema_dataset
      c = column
      ds = db.from(table)
      if !db.table_exists?(table)
        db.create_table(table){String c, :primary_key => true}
      elsif !ds.columns.include?(c)
        raise(Error, "Seeder table #{table} does not contain column #{c}")
      end
      ds
    end
  end
end
