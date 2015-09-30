require 'spec_helper'

Sequel::Seed.environment = :test

describe Sequel.seed do
  it 'should create a Seed descendant according to the current environment' do
    seed = Sequel.seed(:test) do
    end
    expect(Sequel::Seed.descendants).to include seed
  end

  it 'should ignore a Seed not applicable to the current environment' do
    seed = Sequel.seed(:development) do
    end
    expect(Sequel::Seed.descendants).not_to include seed
  end

  it 'should create a Seed applicable to every environment' do
    seed = Sequel.seed do
    end
    expect(Sequel::Seed.descendants).to include seed
  end
end

describe Sequel::Seeder do
  let(:DB) {Sequel.sqlite}

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
          SpecModel.create name: 'some name'
        end
      end

      expect(Sequel::Seed.descendants.length).to be 1
      expect {Sequel::Seeder.apply(DB, '/')}.not_to raise_error
      expect(Sequel::Seed.descendants.length).to be 0
      expect(SpecModel.dataset.all.length).to be 1
      expect(SpecModel.dataset.first.name).to eq 'some name'
    end
  end

  context 'when the specified Seed is not applicable to the current environment' do
    let(:seed) {
      Sequel.seed(:hithere) do
        def run
          SpecModel.create name: 'some name'
        end
      end
    }

    it 'should not make any change to the database' do
      seed
      expect(Sequel::Seed.descendants.length).to be 0
      expect {Sequel::Seeder.apply(DB, '/')}.not_to raise_error
      expect(SpecModel.dataset.all.length).to be 0
    end
  end
end
