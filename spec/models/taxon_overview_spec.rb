require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonOverview do

  def check_delegation_of(method)
    some_string = FactoryGirl.generate(:string)
    @entry.should_receive(method).and_return(some_string)
    @taxon_page_with_entry.send(method).should == some_string
    another_string = FactoryGirl.generate(:string)
    @taxon_concept.should_receive(method).and_return(another_string)
    @taxon_page.send(method).should == another_string
  end

  before(:all) do
    load_foundation_cache
  end

  before(:each) do # NOTE - we want these 'pristine' for each test, because values get cached.
    @taxon_concept = TaxonConcept.gen # Doesn't need to be anything fancy, here.
    @entry = HierarchyEntry.gen
    @user = User.gen
    @taxon_page = TaxonPage.new(@taxon_concept, @user)
    @taxon_page_with_entry = TaxonPage.new(@taxon_concept, @user, @entry)
  end

  # TODO - move these to a spec for the taxon_presenter module
  it "should store the hierarchy entry, when passed in." do
    @taxon_page_with_entry.hierarchy_entry.should == @entry
  end

  it "should know if the hierarchy entry was proided (and thus we're filtering)" do
    @taxon_page.classification_filter?.should_not be_true
    @taxon_page_with_entry.classification_filter?.should be_true
  end

  it "should delegate the hierarchy_entry to taxon_concept, when not passed in" do
    @taxon_concept.should_receive(:entry).and_return('foo')
    @taxon_page.hierarchy_entry.should == 'foo'
  end

  it 'should delegate #gbif_map_id to taxon_concept without an entry' do
    @taxon_concept.should_receive(:gbif_map_id).and_return(36)
    @taxon_page.gbif_map_id.should == 36
  end

  it 'should delegate #gbif_map_id to hierarchy_entry.taxon_concept when available' do
    tc = TaxonConcept.gen
    @entry.should_receive(:taxon_concept).at_least(1).times.and_return(tc)
    tc.should_receive(:gbif_map_id).and_return(98)
    @taxon_page_with_entry.gbif_map_id.should == 98
  end

  # This is (strangely) necessary because TaxonConcept#has_map? actually checks GBIF, not Solr, so it's possible
  # (though not likely) that this could happen:
  it 'should NOT have a map even if the TC says there is one but there is not really one' do
    @taxon_concept.should_receive(:has_map?).and_return(true)
    @taxon_concept.should_receive(:map).and_return(nil)
    @taxon_page.map?.should_not be_true
  end

  it 'should add the map to top_media if available' do
    map = DataObject.gen
    @taxon_concept.should_receive(:has_map?).at_least(1).times.and_return(true)
    @taxon_concept.should_receive(:map).at_least(1).times.and_return(map)
    @taxon_page.top_media.last.should == map
  end

  # Ouch... we need to know a little too much to test this one...  :\
  it 'should filter #top_media on the hierarchy_entry if available' do
    @taxon_concept.should_receive(:images_from_solr).with(4, :filter_hierarchy_entry => @entry,
                                                          :ignore_translations => true).and_return([])
    @taxon_page_with_entry.top_media
  end

  it 'should promote the exemplar image' do
    exemplar = DataObject.gen
    @taxon_concept.should_receive(:images_from_solr).and_return([DataObject.gen, DataObject.gen, exemplar])
    @taxon_concept.should_receive(:published_exemplar_image).at_least(1).times.and_return(exemplar)
    @taxon_page.top_media.first.should == exemplar
  end

  it '#summary should delegate to taxon_concept#overview_text_for_user' do
    @taxon_concept.should_receive(:overview_text_for_user).with(@user).and_return "yay"
    @taxon_page.summary.should == "yay"
  end

  it "#image should delegate to taxon_concept#exemplar_or_best_image_from_solr and pass entry, if provided" do
    @taxon_concept.should_receive(:exemplar_or_best_image_from_solr).with(@entry).and_return "here here"
    @taxon_page_with_entry.image.should == "here here"
  end

  it "#image should delegate to taxon_concept#exemplar_or_best_image_from_solr without entry if missing" do
    @taxon_concept.should_receive(:exemplar_or_best_image_from_solr).with(@taxon_concept.entry).and_return "there there"
    @taxon_page.image.should == "there there"
  end

  # TODO - move these to the TaxonPresenter spec
  it '#to_param should add entry#to_param (with path) to taxon_concept#to_param if provided' do
    @taxon_page_with_entry.to_param.should == "#{@taxon_concept.to_param}/hierarchy_entries/#{@entry.to_param}"
  end

  it '#to_param should delegate to taxon_concept with no entry' do
    @taxon_page.to_param.should == @taxon_concept.to_param
  end

end
