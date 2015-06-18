require "spec_helper"

describe TaxonOverview do

  before(:all) do
    load_foundation_cache  
    @res = Resource.gen(title: "IUCN Structured Data")  
  end

  before(:each) do # NOTE - we want these 'pristine' for each test, because values get cached.
    @taxon_concept = TaxonConcept.gen # Doesn't need to be anything fancy, here.
    @native_entry = HierarchyEntry.gen(taxon_concept: @taxon_concept)
    @entry = HierarchyEntry.gen
    @language = Language.gen(iso_639_1: 'aa')
    @user = User.gen(language: @language)
    @overview = TaxonOverview.new(@taxon_concept, @user)
    @overview_with_entry = TaxonOverview.new(@taxon_concept, @user, @entry)
  end

  # This is (strangely) necessary because TaxonConcept#has_map? actually checks GBIF, not Solr, so it's possible
  # (though not likely) that this could happen:
  it 'should NOT have a map even if the TC says there is one but there is not really one' do
    @taxon_concept.should_receive(:has_map?).and_return(true)
    @taxon_concept.should_receive(:get_one_map_from_solr).and_return([nil])
    @overview.map?.should_not be_true
  end

  it 'should add the map to media if available' do
    map = DataObject.gen
    @taxon_concept.should_receive(:has_map?).at_least(1).times.and_return(true)
    @taxon_concept.should_receive(:get_one_map_from_solr).at_least(1).times.and_return([map])
    @overview = TaxonOverview.new(@taxon_concept, @user) # NOTE - you MUST rebuild the overview if you add media to it, since it's preloaded.
    @overview.media.last.should == map
  end

  it 'should promote the exemplar image' do
    exemplar = DataObject.gen
    @taxon_concept.should_receive(:images_from_solr).at_least(1).times.and_return([DataObject.gen, DataObject.gen, DataObject.gen, DataObject.gen, exemplar])
    @taxon_concept.should_receive(:published_exemplar_image).at_least(1).times.and_return(exemplar)
    @overview = TaxonOverview.new(@taxon_concept, @user) # NOTE - you MUST rebuild the overview if you add media to it, since it's preloaded.
    @overview.media.first.should == exemplar
    @overview.media.length.should_not > TaxonOverview::MEDIA_TO_SHOW
  end

  it '#summary should delegate to taxon_concept#overview_text_for_user' do
    overtext = DataObject.gen
    @taxon_concept.should_receive(:overview_text_for_user).with(@user).and_return overtext
    @overview = TaxonOverview.new(@taxon_concept, @user) # NOTE - you MUST rebuild the overview if you add media to it, since it's preloaded.
    @overview.summary.should == overtext
  end

  it "#image should delegate to taxon_concept#exemplar_or_best_image_from_solr and pass entry, if provided" do
    @taxon_concept.should_receive(:exemplar_or_best_image_from_solr).with(@entry).and_return "here here"
    @overview_with_entry.image.should == "here here"
  end

  it "#image should delegate to taxon_concept#exemplar_or_best_image_from_solr without entry if missing" do
    img = DataObject.gen
    @taxon_concept.should_receive(:exemplar_or_best_image_from_solr).with(nil).and_return img
    @overview.image.should == img
  end

  # TODO - move these to the TaxonPresenter spec
  it '#to_param should add entry#to_param (with path) to taxon_concept#to_param if provided' do
    @overview_with_entry.to_param.should == "#{@taxon_concept.to_param}/hierarchy_entries/#{@entry.to_param}"
  end

  it '#to_param should delegate to taxon_concept with no entry' do
    @overview.to_param.should == @taxon_concept.to_param
  end

  # TODO - hard to test, refactor
  it '#details? should check if details exist with only one detail (and not preload)' do
    @taxon_concept.should_receive(:text_for_user).with(
      @user, 
      language_ids: [ @user.language_id ],
      filter_by_subtype: true,
      allow_nil_languages: @user.default_language?,
      toc_ids_to_ignore: TocItem.exclude_from_details.collect { |toc_item| toc_item.id },
      per_page: 1
    ).and_return(true)
    DataObject.should_not_receive(:preload_associations)
    @overview.details?.should be_true
  end

  it 'should know its classification' do
    @entry.should_receive(:hierarchy).and_return("Bob was not here")
    @overview_with_entry.classification.should == "Bob was not here"
  end

  it 'should know who chose its classification' do
    user = User.gen
    chosen = CuratedTaxonConceptPreferredEntry.gen(user: user)
    @overview.should_receive(:curator_chosen_classification).and_return(chosen)
    @overview.classification_chosen_by.should == user
  end

  it 'should know when its classification has been selected by curator' do
    stubby = CuratedTaxonConceptPreferredEntry.gen
    @overview.should_receive(:curator_chosen_classification).and_return stubby
    @overview.classification_curated?.should be_true
    another_overview = TaxonOverview.new(TaxonConcept.gen, User.gen)
    another_overview.classification_curated?.should_not be_true
  end

  it 'should know how many classifications it has available' do
    hiers = []
    4.times { hiers << HierarchyEntry.gen(taxon_concept: @taxon_concept) }
    @taxon_concept.should_receive(:published_hierarchy_entries).and_return(hiers)
    @overview.classifications_count.should == 4
  end

  it 'should pick random hierarchy entry' do
    @overview.stub_chain(:hierarchy_entries, :shuffle, :first).and_return("yay")
    @overview.hierarchy_entry.should == 'yay'
  end

  it 'should grab an unpublished hierarchy entry when there are no others'

  it 'should pick the three most relevant collections' do
    one = Collection.gen
    one.stub(:relevance).and_return(2)
    two = Collection.gen
    two.stub(:relevance).and_return(5)
    three = Collection.gen
    three.stub(:relevance).and_return(3)
    four = Collection.gen
    four.stub(:relevance).and_return(6)
    @taxon_concept.stub_chain(:published_containing_collections, :select).and_return([one, two, three, four])
    @overview.collections.map(&:id).should == [four, two, three].map(&:id)
  end

  it 'should know how many collections are available' do
    @taxon_concept.stub_chain(:published_containing_collections, :select).and_return([1,2,3,4,5,6])
    @overview.collections_count.should == 6
  end

  # TODO ... eww.  Lots of setup.  We could minimize this by fixing the query and moving things around:
  it 'should grab the three communities with the most members' do
    communities = []
    [2, 6, 3, 9].each do |count|
      communities << Community.gen
      collection = Collection.gen
      collection.add @taxon_concept
      communities.last.collections << collection
      count.times { Member.gen(community_id: communities.last.id) }
    end
    @overview.communities.map(&:id).sort.should == [communities[1], communities[2], communities[3]].map(&:id).sort
  end

  it 'should know how many communities are available' do
    @taxon_concept.should_receive(:communities).and_return([1,2,3,4,5])
    @overview.communities_count.should == 5
  end

  it 'should have a list of curators' do
    @taxon_concept.should_receive(:data_object_curators).and_return('blah blah')
    @overview.curators.should == 'blah blah'
  end

  it 'should know how many curators there are' do
    @taxon_concept.should_receive(:data_object_curators).and_return([1,2,3,4,5,6,7])
    @overview.curators_count.should == 7
  end

  it 'should know the last five activities from the activity_log' do
    @taxon_concept.should_receive(:activity_log).with(per_page: 5, user: @user).and_return('hi from activity')
    @overview.activity_log.should == 'hi from activity'
  end

  it 'should get one map from the taxon_concept' do
    @taxon_concept.should_receive(:get_one_map_from_solr).and_return(['one map', 'not_another'])
    @overview.map.should == 'one map'
  end

  it 'should know iucn status' do
    (DataMeasurement.new(predicate: "<http://rs.tdwg.org/ontology/voc/SPMInfoItems#ConservationStatus>", object: "Wunderbar", resource: @res, subject: @taxon_concept)).add_to_triplestore    
    @overview.iucn_status.should == 'Wunderbar'
  end
  
  it 'has default iucn status = nil' do
    expect(@overview.iucn_status).to be_nil
  end
  
  it 'has default iucn url = nil' do    
    expect(@overview.iucn_url).to be_nil
  end

  it 'should generate a normalized cache id' do
    @overview.cache_id.should == "taxon_overview_#{@taxon_concept.id}_#{@language.iso_639_1}"
  end

end
