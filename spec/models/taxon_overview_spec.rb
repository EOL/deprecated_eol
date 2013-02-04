require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonOverview do

  def check_delegation_of(method)
    some_string = FactoryGirl.generate(:string)
    @entry.should_receive(method).and_return(some_string)
    @overview_with_entry.send(method).should == some_string
    another_string = FactoryGirl.generate(:string)
    @taxon_concept.should_receive(method).and_return(another_string)
    @overview.send(method).should == another_string
  end

  before(:all) do
    load_foundation_cache
  end

  before(:each) do # NOTE - we want these 'pristine' for each test, because values get cached.
    @taxon_concept = TaxonConcept.gen # Doesn't need to be anything fancy, here.
    @native_entry = HierarchyEntry.gen
    @taxon_concept.stub!(:hierarchy_entries).and_return([@native_entry])
    @entry = HierarchyEntry.gen
    @user = User.gen
    @overview = TaxonOverview.new(@taxon_concept, @user)
    @overview_with_entry = TaxonOverview.new(@taxon_concept, @user, @entry)
  end

  # This is (strangely) necessary because TaxonConcept#has_map? actually checks GBIF, not Solr, so it's possible
  # (though not likely) that this could happen:
  it 'should NOT have a map even if the TC says there is one but there is not really one' do
    @taxon_concept.should_receive(:has_map?).and_return(true)
    @taxon_concept.should_receive(:get_one_map).and_return(nil)
    @overview.map?.should_not be_true
  end

  it 'should add the map to media if available' do
    map = DataObject.gen
    @taxon_concept.should_receive(:has_map?).at_least(1).times.and_return(true)
    @taxon_concept.should_receive(:get_one_map).at_least(1).times.and_return(map)
    @overview = TaxonOverview.new(@taxon_concept, @user) # NOTE - you MUST rebuild the overview if you add media to it, since it's preloaded.
    @overview.media.last.should == map
  end

  # Ouch... we need to know a little too much to test this one...  :\
  it 'should filter #media on the hierarchy_entry if available' do
    @taxon_concept.should_receive(:images_from_solr).with(4, :filter_hierarchy_entry => @entry,
                                                          :ignore_translations => true).and_return([])
    @overview_with_entry = TaxonOverview.new(@taxon_concept, @user, @entry) # NOTE - you MUST rebuild the overview if you add media to it, since it's preloaded.
    @overview_with_entry.media
  end

  it 'should promote the exemplar image' do
    $FOO = 1
    exemplar = DataObject.gen
    @taxon_concept.should_receive(:images_from_solr).at_least(1).times.and_return([DataObject.gen, DataObject.gen, exemplar])
    @taxon_concept.should_receive(:published_exemplar_image).at_least(1).times.and_return(exemplar)
    @overview = TaxonOverview.new(@taxon_concept, @user) # NOTE - you MUST rebuild the overview if you add media to it, since it's preloaded.
    @overview.media.first.should == exemplar
  end

  it '#summary should delegate to taxon_concept#overview_text_for_user' do
    @taxon_concept.should_receive(:overview_text_for_user).with(@user).and_return "yay"
    @overview.summary.should == "yay"
  end

  it "#image should delegate to taxon_concept#exemplar_or_best_image_from_solr and pass entry, if provided" do
    @taxon_concept.should_receive(:exemplar_or_best_image_from_solr).with(@entry).and_return "here here"
    @overview_with_entry.image.should == "here here"
  end

  it "#image should delegate to taxon_concept#exemplar_or_best_image_from_solr without entry if missing" do
    img = DataObject.gen
    @taxon_concept.should_receive(:exemplar_or_best_image_from_solr).with(@native_entry).and_return img
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
      :language_ids => [ @user.language_id ],
      :filter_by_subtype => true,
      :allow_nil_languages => @user.default_language?,
      :toc_ids_to_ignore => TocItem.exclude_from_details.collect { |toc_item| toc_item.id },
      :per_page => 1
    ).and_return(true)
    DataObject.should_not_receive(:preload_associations)
    @overview.details?.should be_true
  end

end
