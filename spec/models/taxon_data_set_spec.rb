require "spec_helper"

describe TaxonDataSet do

  before(:all) do
    load_foundation_cache
    @taxon_concept = TaxonConcept.gen
  end

  before(:each) do
    @row_1 = { trait: Trait.gen.uri }
    @row_2 = { trait: Trait.gen.uri }
    @row_3 = { trait: Trait.gen.uri }
    @row_4 = { trait: Trait.gen.uri }
    @rows = [ @row_1, @row_2, @row_3, @row_4 ]
  end

  it 'should populate Trait instances by taxon concept and uri' do
    trait = Trait.gen(taxon_concept: @taxon_concept, uri: "http://something/new/")
    @row_1[:trait] = trait.uri
    set = TaxonDataSet.new(@rows, taxon_concept: @taxon_concept)
    set.first.should == trait
  end

  it 'should create data point uris where not available, given a uri' do
    Trait.delete_all
    uri = "http://some.place.fun/has_stuff/21" # FactoryGirl.generate(:uri) ?
    @row_1[:trait] = uri
    set = TaxonDataSet.new(@rows, taxon_concept: @taxon_concept)
    set.first.should_not be_nil
    Trait.first.uri.should == uri
  end

  # NOTE - we maybe shouldn't care about this, since it's "just" efficiency. But hey.
  it 'should preload associations on data point uris.' do
    Trait.should_receive(:preload_associations).at_least(2).times
    TaxonDataSet.new(@rows, taxon_concept: @taxon_concept)
  end

  it 'should yield each row on each' do
    set = TaxonDataSet.new(@rows, taxon_concept: @taxon_concept)
    index = 0
    set.each_with_index do |trait, index|
      trait.uri == instance_variable_get("@row_#{index+1}")[:trait]
    end
  end

  it 'should sort by position (with unknown uris at the end)' do
    # acts_as_tree does strange things when you create positions out of order
    uri1 = KnownUri.gen(position: 1)
    uri2 = KnownUri.gen(position: 2)
    uri3 = KnownUri.gen(position: 3)
    uri4 = KnownUri.gen(position: 4)
    uri5 = KnownUri.gen(position: 5)
    raw_uri1 = 'http://somewhere/a'
    raw_uri2 = 'http://somewhere/b'
    raw_uri3 = 'http://somewhere/c'
    rows = [
      { trait: 'http://eol.org/1', attribute: uri5 },
      { trait: 'http://eol.org/2', attribute: raw_uri3 },
      { trait: 'http://eol.org/3', attribute: uri4 },
      { trait: 'http://eol.org/4', attribute: uri2 },
      { trait: 'http://eol.org/5', attribute: raw_uri1 },
      { trait: 'http://eol.org/6', attribute: uri1 },
      { trait: 'http://eol.org/7', attribute: raw_uri2 },
      { trait: 'http://eol.org/8', attribute: uri3 }
    ]
    set = TaxonDataSet.new(rows, taxon_concept: @taxon_concept)
    set.sort.map { |r| r.predicate }.should == [
      uri1.uri, uri2.uri, uri3.uri, uri4.uri, uri5.uri, raw_uri1, raw_uri2, raw_uri3
    ]
  end
end
