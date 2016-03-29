require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonUserClassificationFilter do

  def check_delegation_of(method)
    some_string = FactoryGirl.generate(:string)
    @entry.should_receive(method).and_return(some_string)
    @taxon_page_with_entry.send(method).should == some_string
    another_string = FactoryGirl.generate(:string)
    @taxon_concept.should_receive(method).and_return(another_string)
    @taxon_page.send(method).should == another_string
  end

  before(:all) do
    populate_tables(:visibilities)
  end

  before do # NOTE - we want these 'pristine' for each test, because values get cached.
    @taxon_concept = TaxonConcept.gen # Doesn't need to be anything fancy, here.
    @entry = HierarchyEntry.gen
    @user = User.gen
    @taxon_page = TaxonUserClassificationFilter.new(@taxon_concept, @user)
    @taxon_page_with_entry = TaxonUserClassificationFilter.new(@taxon_concept, @user, @entry)
  end

  it 'should default to an Anonymous User' do
    TaxonUserClassificationFilter.new(@taxon_concept).user.should be_a(EOL::AnonymousUser)
  end

  it "should be able to filter related_names by taxon_concept" # Yeesh, this is really hard to test.

  it "should be able to filter related_names by hierarchy_entry" # Yeesh, this is really hard to test.

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

  it "should intelligently delegate #hierarchy" do
    check_delegation_of(:hierarchy)
  end

  it "should delegate damn near everything to TaxonConcept" do
    @taxon_concept.should_receive(:whatever).with(:foo).and_return "something"
    @taxon_page.whatever(:foo).should == "something"
  end

  # TODO - this is painful enough that we're probably not doing this in the best way.  :\
  it "should delegeate hierarchy_entries to TaxonConcept#published_browsable_hierarchy_entries" do
    phes = @taxon_concept.published_browsable_hierarchy_entries
    phes.should be_empty # Later test won't work if it's not.
    @taxon_concept.should_receive(:published_browsable_hierarchy_entries).and_return(phes)
    @taxon_page.hierarchy_entries.should == []
  end

  it "should return the provided hierarchy_entry if there are no hierarchy_entries" do
    @taxon_page_with_entry.hierarchy_entries.should == [@entry]
  end

  it 'should NOT have a hierarchy_provider without a hierarchy_entry' do
    @taxon_page.hierarchy_provider.should be_nil
  end

  it 'should grab hierarchy_provider from hierarchy_entry if available' do
    @entry.should_receive(:hierarchy_provider).and_return("yo")
    @taxon_page_with_entry.hierarchy_provider.should == "yo"
  end

  it '#scientific_name comes from #title_canonical_italicized' do
    @entry.should_receive(:title_canonical_italicized).and_return "mush"
    @taxon_page_with_entry.scientific_name.should == "mush"
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
    @user.should_receive(:min_curator_level?).with(:assistant).and_return(false)
    @taxon_page.can_set_exemplars?.should_not be_true
  end

  it 'should allow exemplar-setting when the user is an assistant curator' do
    @user.should_receive(:min_curator_level?).with(:assistant).and_return(true)
    @taxon_page.can_set_exemplars?.should be_true
  end

  # TODO - this is hard to test, so we're probably doing something wrong.
  it '#related_names should call a really nasty query for parents and children' do
    # http://stackoverflow.com/questions/1785382/rspec-expecting-a-message-multiple-times-but-with-differing-parameters
    mock_connection = double("connection").as_null_object
    HierarchyEntry.stub(:connection).and_return(mock_connection) # scary...
    mock_connection.should_receive(:execute).once.with("
      SELECT n.id name_id, n.string name_string, n.canonical_form_id, he_parent.taxon_concept_id,
        h.label hierarchy_label, he_parent.id hierarchy_entry_id
      FROM hierarchy_entries he_parent
      JOIN hierarchy_entries he_child ON (he_parent.id=he_child.parent_id)
      JOIN names n ON (he_parent.name_id=n.id)
      JOIN hierarchies h ON (he_child.hierarchy_id=h.id)
      WHERE he_child.taxon_concept_id=#{@taxon_concept.id}
      AND he_parent.published = 1
      AND browsable = 1
    ")
    mock_connection.should_receive(:execute).once.with("
      SELECT n.id name_id, n.string name_string, n.canonical_form_id, he_child.taxon_concept_id,
        h.label hierarchy_label, he_child.id hierarchy_entry_id
      FROM hierarchy_entries he_parent
      JOIN hierarchy_entries he_child ON (he_parent.id=he_child.parent_id)
      JOIN names n ON (he_child.name_id=n.id)
      JOIN hierarchies h ON (he_parent.hierarchy_id=h.id)
      WHERE he_parent.taxon_concept_id=#{@taxon_concept.id}
      AND he_child.published = 1
      AND browsable = 1
    ")
    @taxon_page.related_names
  end

  # TODO - this is hard to test, so we're probably doing something wrong.
  it '#related_names should call a really nasty query for parents and children when entry specified' do
    # http://stackoverflow.com/questions/1785382/rspec-expecting-a-message-multiple-times-but-with-differing-parameters
    mock_connection = double("connection").as_null_object
    HierarchyEntry.stub(:connection).and_return(mock_connection) # scary...
    mock_connection.should_receive(:execute).once.with("
      SELECT n.id name_id, n.string name_string, n.canonical_form_id, he_parent.taxon_concept_id,
        h.label hierarchy_label, he_parent.id hierarchy_entry_id
      FROM hierarchy_entries he_parent
      JOIN hierarchy_entries he_child ON (he_parent.id=he_child.parent_id)
      JOIN names n ON (he_parent.name_id=n.id)
      JOIN hierarchies h ON (he_child.hierarchy_id=h.id)
      WHERE he_child.id=#{@entry.id}
      AND he_parent.published = 1
      AND browsable = 1
    ")
    mock_connection.should_receive(:execute).once.with("
      SELECT n.id name_id, n.string name_string, n.canonical_form_id, he_child.taxon_concept_id,
        h.label hierarchy_label, he_child.id hierarchy_entry_id
      FROM hierarchy_entries he_parent
      JOIN hierarchy_entries he_child ON (he_parent.id=he_child.parent_id)
      JOIN names n ON (he_child.name_id=n.id)
      JOIN hierarchies h ON (he_parent.hierarchy_id=h.id)
      WHERE he_parent.id=#{@entry.id}
      AND he_child.published = 1
      AND browsable = 1
    ")
    @taxon_page_with_entry.related_names
  end

  it '#related_names should create a hash with parents and childten' do
    @taxon_page_with_entry.related_names.should == {'parents' => [], 'children' => []}
    @taxon_page.related_names.should == {'parents' => [], 'children' => []}
  end

  # TODO - this is really hard to test... hard enough that I'm not going to bother... which suggests perhaps we
  # should be doing something else.
  it '#related_names should build the expected hash from the results'

  it 'should cound all related names' do
    @taxon_page.should_receive(:related_names).twice.and_return('parents' => [1,2,3], 'children' => [4,5,6,7])
    @taxon_page.related_names_count.should == 7
  end

  # Hard to test.  :\  ...Though the "spirit" of this may be captured in other specs...
  it 'should show details text with no language only to users in the default language'

  it '#common_names should call EOL::CommonNameDisplay.find_by_hierarchy_entry_id when entry provided' do
    EOL::CommonNameDisplay.should_receive(:find_by_hierarchy_entry_id).with(@entry.id, foo: 'bar').and_return([])
    @taxon_page_with_entry.common_names(foo: 'bar')
  end

  it '#common_names should call EOL::CommonNameDisplay.find_by_taxon_concept_id when no entry provided' do
    EOL::CommonNameDisplay.should_receive(:find_by_taxon_concept_id).with(@taxon_concept.id, nil, b: 'o').and_return([])
    @taxon_page.common_names(b: 'o')
  end

  it '#facets should ignore entry if none provided' do
    EOL::Solr::DataObjects.should_receive(:get_aggregated_media_facet_counts).with(
      @taxon_concept.id, user: @user
    )
    @taxon_page.facets
  end

  it "#text should delegate to taxon_concept#text_for_user and pass options" do
    @taxon_concept.should_receive(:text_for_user).with(@user, foo: 'bar').and_return "that worked"
    @taxon_page.text(foo: 'bar').should == "that worked"
  end

  # TODO - move these to the TaxonPresenter spec
  it '#to_param should add entry#to_param (with path) to taxon_concept#to_param if provided' do
    @taxon_page_with_entry.to_param.should == "#{@taxon_concept.to_param}/hierarchy_entries/#{@entry.to_param}"
  end

  it '#to_param should delegate to taxon_concept with no entry' do
    @taxon_page.to_param.should == @taxon_concept.to_param
  end

  it 'should intelligently delegate #rank_label' do
    check_delegation_of(:rank_label)
  end
end
