require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonPage do

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

  it "should be able to filter related_names by taxon_concept" # Yeesh, this is really hard to test.

  it "should be able to filter related_names by hierarchy_entry" # Yeesh, this is really hard to test.

  it "should store the hierarchy entry, when passed in." do
    @taxon_page_with_entry.entry.should == @entry
  end

  it "should delegate the hierarchy_entry to taxon_concept, when not passed in" do
    @taxon_concept.should_receive(:entry).and_return('foo')
    @taxon_page.entry.should == 'foo'
  end

  it "should delegate #hiearchy to the hierarchy_entry, when provided" do
    @entry.should_receive(:hierarchy).and_return "here"
    @taxon_page_with_entry.hierarchy.should == "here"
  end

  it "should delegate #hierarchy to the taxon_concept, when no entry provided" do
    @taxon_concept.should_receive(:hierarchy).and_return "this"
    @taxon_page.hierarchy.should == "this"
  end

  it "should delegate damn near everything to TaxonConcept" do
    @taxon_concept.should_receive(:whatever).with(:foo).and_return "something"
    @taxon_page.whatever(:foo).should == "something"
  end

  # TODO - this is painful enough that we're probably not doing this in the best way.  :\
  it "should delegeate hierarchy_entries to TaxonConcept#published_hierarchy_entries" do
    phes = @taxon_concept.published_hierarchy_entries
    phes.should be_empty # Later test won't work if it's not.
    @taxon_concept.should_receive(:published_hierarchy_entries).and_return(phes)
    @taxon_page.hierarchy_entries.should == []
  end

  it "should return the provided hierarchy_entry if there are no published_hierarchy_entries" do
    @taxon_page_with_entry.hierarchy_entries.should == [@entry]
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

  # This is (strangely) necessary because TaxonConcept#has_map actually checks GBIF, not Solr, so it's possible
  # (though not likely) that this could happen:
  it 'should NOT have a map even if the TC says there is one but there is not really one' do
    @taxon_concept.should_receive(:has_map).and_return(true)
    @taxon_concept.should_receive(:map).and_return(nil)
    @taxon_page.map?.should_not be_true
  end

  it 'should add the map to top_media if available' do
    map = DataObject.gen
    @taxon_concept.should_receive(:has_map).at_least(1).times.and_return(true)
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

  it 'should NOT have a hierarchy_provider without a hierarchy_entry' do
    @taxon_page.hierarchy_provider.should be_nil
  end

  it 'should grab hierarchy_provider from hierarchy_entry if available' do
    @entry.should_receive(:hierarchy_provider).and_return("yo")
    @taxon_page_with_entry.hierarchy_provider.should == "yo"
  end

  # TODO - PL says "it would be good to test with something thats a surrogate name - one of the Unidentified sp 2342
  # or a virus name" ...which we don't want to do here, but we should do elsewhere...
  it 'should get title from entry when availble' do
    @entry.should_receive(:title_canonical_italicized).and_return "mush"
    @taxon_page_with_entry.scientific_name.should == "mush"
  end

  it 'should get title from taxon_concept when no entry availble' do
    @taxon_concept.should_receive(:title_canonical_italicized).and_return "goober"
    @taxon_page.scientific_name.should == "goober"
  end

  # NOTE - we count using two different algorithms.  :\
  it 'should check the entry for synonyms when available' do
    @entry.should_receive(:scientific_synonyms).and_return([1,2,3])
    @taxon_page_with_entry.synonyms?.should be_true
  end

  it 'should check the entry for synonyms (and find none) when available' do
    @entry.should_receive(:scientific_synonyms).and_return([])
    @taxon_page_with_entry.synonyms?.should_not be_true
  end

  # NOTE - we count using two different algorithms.  :\
  it 'should check the taxon_concept for synonyms when no entry available' do
    @taxon_concept.should_receive(:count_of_viewable_synonyms).and_return(2)
    @taxon_page.synonyms?.should be_true
  end

  it 'should check the taxon_concept for synonyms (and find none) when no entry available' do
    @taxon_concept.should_receive(:count_of_viewable_synonyms).and_return(0)
    @taxon_page.synonyms?.should_not be_true
  end

  it 'should not allow reindexing when hierarchy_entry provided' do
    @taxon_page_with_entry.can_be_reindexed?.should_not be_true
  end

  it 'should NOT allow reindexing when the user is not a master' do
    @user.should_receive(:min_curator_level?).with(:master).and_return(false)
    @taxon_page.can_be_reindexed?.should_not be_true
  end

  it 'should allow reindexing when the user is a master' do
    @user.should_receive(:min_curator_level?).with(:master).and_return(true)
    @taxon_page.can_be_reindexed?.should be_true
  end

  it 'should not allow exemplar-setting when hierarchy_entry provided' do
    @taxon_page_with_entry.can_set_exemplars?.should_not be_true
  end

  it 'should NOT allow exemplar-setting when the user is not a curator' do
    @user.should_receive(:min_curator_level?).with(:master).and_return(false)
    @taxon_page.can_set_exemplars?.should_not be_true
  end

  it 'should allow exemplar-setting when the user is a master' do
    @user.should_receive(:min_curator_level?).with(:master).and_return(true)
    @taxon_page.can_set_exemplars?.should be_true
  end



end
