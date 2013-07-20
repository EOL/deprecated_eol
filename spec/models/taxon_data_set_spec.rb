require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonDataSet do

  before(:all) do
    @taxon_concept = TaxonConcept.gen
  end

  before(:each) do
    @row_1 = {id: 1}
    @row_2 = {id: 2}
    @row_3 = {id: 3}
    @rows = [@row_1, @row_2, @row_3]
  end

  it 'should populate DataPointUri instances by taxon concept and uri' do
    dpuri = DataPointUri.gen(taxon_concept: @taxon_concept)
    @row_1[:data_point_uri] = dpuri.uri
    set = TaxonDataSet.new(@rows, taxon_concept_id: @taxon_concept.id)
    set.first[:data_point_instance].should == dpuri
  end

  it 'should create data point uris where not available, given a uri' do
    DataPointUri.delete_all
    uri = "http://some.place.fun/has_stuff/21" # FactoryGirl.generate(:uri) ?
    @row_1[:data_point_uri] = uri
    set = TaxonDataSet.new(@rows, taxon_concept_id: @taxon_concept.id)
    set.first[:data_point_instance].should_not be_nil
    DataPointUri.first.uri.should == uri
  end

  # NOTE - we maybe shouldn't care about this, since it's "just" efficiency. But hey.
  it 'should preload associations on data point uris.' do
    DataPointUri.should_receive(:preload_associations)
    TaxonDataSet.new(@rows, taxon_concept_id: @taxon_concept.id)
  end

  it 'should yield each row on each' do
    set = TaxonDataSet.new(@rows, taxon_concept_id: @taxon_concept.id)
    index = 0
    set.each do |row|
      row[:id].should == index += 1
    end
  end

  it 'should sort by position (with unknown uris at the end)' do
    rows = [
      {attribute: uri5 = KnownUri.gen(position: 5)},
      {attribute: raw_uri3 = 'http://somewhere/c'},
      {attribute: uri4 = KnownUri.gen(position: 4)},
      {attribute: uri2 = KnownUri.gen(position: 2)},
      {attribute: raw_uri1 = 'http://somewhere/a'},
      {attribute: uri1 = KnownUri.gen(position: 1)},
      {attribute: raw_uri2 = 'http://somewhere/b'},
      {attribute: uri3 = KnownUri.gen(position: 3)}
    ]
    set = TaxonDataSet.new(rows, taxon_concept_id: @taxon_concept.id)
    set.sort.map { |r| r[:attribute] }.should == [
      uri1, uri2, uri3, uri4, uri5, raw_uri1, raw_uri2, raw_uri3
    ]
  end

end
