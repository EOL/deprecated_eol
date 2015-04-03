require "spec_helper"

describe EOL::Sparql::UnitQueryBuilder do
  before(:all) do
    load_foundation_cache
    @unit_builder = EOL::Sparql::UnitQueryBuilder.new('unit', 1, 2)
  end

  describe '#initialize' do
    it 'should create an instance' do
      expect(EOL::Sparql::UnitQueryBuilder.new('unit', 1, 2)).to be_a(EOL::Sparql::UnitQueryBuilder)
    end
  end

  describe '#identical_uris' do
    it 'know which units we consider to be identical' do
      expect(@unit_builder.identical_uris(KnownUri.grams.uri)).to eq(
        Trait.conversions.detect{ |c|
          c[:starting_units].include?(KnownUri.grams.uri) }[:starting_units])
    end

    it 'know which units are not identical to anything' do
      expect(@unit_builder.identical_uris('nothing')).to eq([ 'nothing' ])
    end
  end

end
