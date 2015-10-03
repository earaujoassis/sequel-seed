require 'spec_helper'

Sequel::Seed.environment = :test

describe Sequel.seed do
  it 'should create a Seed descendant according to the current environment' do
    seed = Sequel.seed(:test) {}
    expect(Sequel::Seed.descendants).to include seed
  end

  it 'should ignore a Seed not applicable to the current environment' do
    seed = Sequel.seed(:development) {}
    expect(Sequel::Seed.descendants).not_to include seed
  end

  it 'should create a Seed applicable to every environment' do
    seed = Sequel.seed {}
    expect(Sequel::Seed.descendants).to include seed
  end
end

describe Sequel::Seeder do
  let(:DB) {Sequel.sqlite}

  describe 'environment references should be indistinguishable between Symbol and String' do
    context 'when the environment is defined using a String' do
      it 'should apply the Seed accordingly' do
        Sequel::Seed.environment = "test"

        Sequel.seed(:test) do
          def run
            SpecModel.create :name => 'environment defined by String'
          end
        end

        expect(Sequel::Seed.descendants.length).to be 1
        expect {Sequel::Seeder.apply(DB, '/')}.not_to raise_error
        expect(Sequel::Seed.descendants.length).to be 0
        expect(SpecModel.dataset.all.length).to be 1
        expect(SpecModel.dataset.first.name).to eq 'environment defined by String'
      end
    end

    context 'when the Seed is defined using a String' do
      it 'should apply the Seed accordingly' do
        Sequel::Seed.environment = :test

        Sequel.seed("test") do
          def run
            SpecModel.create :name => 'Seed defined by String'
          end
        end

        expect(Sequel::Seed.descendants.length).to be 1
        expect {Sequel::Seeder.apply(DB, '/')}.not_to raise_error
        expect(Sequel::Seed.descendants.length).to be 0
        expect(SpecModel.dataset.all.length).to be 1
        expect(SpecModel.dataset.first.name).to eq 'Seed defined by String'
      end
    end

    context 'when both Seed and environment are defined using a String' do
      it 'should apply the Seed accordingly' do
        Sequel::Seed.environment = "test"

        Sequel.seed("test") do
          def run
            SpecModel.create :name => 'Seed and environment defined by String'
          end
        end

        expect(Sequel::Seed.descendants.length).to be 1
        expect {Sequel::Seeder.apply(DB, '/')}.not_to raise_error
        expect(Sequel::Seed.descendants.length).to be 0
        expect(SpecModel.dataset.all.length).to be 1
        expect(SpecModel.dataset.first.name).to eq 'Seed and environment defined by String'
      end
    end

    context 'when both Seed and environment are defined using a Symbol' do
      it 'should apply the Seed accordingly' do
        Sequel::Seed.environment = :test

        Sequel.seed(:test) do
          def run
            SpecModel.create :name => 'Seed and environment defined by Symbol'
          end
        end

        expect(Sequel::Seed.descendants.length).to be 1
        expect {Sequel::Seeder.apply(DB, '/')}.not_to raise_error
        expect(Sequel::Seed.descendants.length).to be 0
        expect(SpecModel.dataset.all.length).to be 1
        expect(SpecModel.dataset.first.name).to eq 'Seed and environment defined by Symbol'
      end
    end

    context 'when the environment is defined using a String and we have a wildcard Seed' do
      it 'should apply the Seed accordingly' do
        Sequel::Seed.environment = "test"

        Sequel.seed do
          def run
            SpecModel.create :name => 'Wildcard Seed and environment defined by String'
          end
        end

        expect(Sequel::Seed.descendants.length).to be 1
        expect {Sequel::Seeder.apply(DB, '/')}.not_to raise_error
        expect(Sequel::Seed.descendants.length).to be 0
        expect(SpecModel.dataset.all.length).to be 1
        expect(SpecModel.dataset.first.name).to eq 'Wildcard Seed and environment defined by String'
      end
    end
  end

  context 'when there\'s no Seed created' do
    it 'should not make any change to the database' do
      expect {Sequel::Seeder.apply(DB, '/')}.not_to raise_error
      expect(SpecModel.dataset.all.length).to be 0
    end
  end

  context 'when there\'s a Seed created' do
    it 'should change the database accordingly only once' do
      Sequel.seed do
        def run
          SpecModel.create :name => 'should have changed'
        end
      end

      expect(Sequel::Seed.descendants.length).to be 1
      expect {Sequel::Seeder.apply(DB, '/')}.not_to raise_error
      expect(Sequel::Seed.descendants.length).to be 0
      expect(SpecModel.dataset.all.length).to be 1
      expect(SpecModel.dataset.first.name).to eq 'should have changed'
    end
  end

  context 'when the specified Seed is not applicable to the current environment' do
    it 'should not make any change to the database' do
      Sequel.seed(:hithere) do
        def run
          SpecModel.create :name => 'should not have changed'
        end
      end

      expect(Sequel::Seed.descendants.length).to be 0
      expect {Sequel::Seeder.apply(DB, '/')}.not_to raise_error
      expect(SpecModel.dataset.all.length).to be 0
    end
  end
end
