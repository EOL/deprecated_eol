require "spec_helper"

describe TaxonDetails do

  # I'm not testing all of the args, here... there are WAY too many to be worthwhile.
  def prep_details(texts)
    @taxon_concept.should_receive(:text_for_user).at_least(1).times.and_return(texts)
    DataObject.should_receive(:preload_associations).at_least(1).times.and_return(texts)
    DataObject.should_receive(:sort_by_rating).with(texts, @taxon_concept).at_least(1).times.and_return(texts)
  end

  def should_get_sym_when_toc_includes(symbol, toc_method)
    tocs = Array(TocItem.send(toc_method)).map { |item| item.respond_to?(:id) ? item.id : item }
    EOL::Solr::DataObjects.should_receive(:unique_toc_ids).and_return(tocs)
    @details.resources_links.should include(symbol)
  end

  def should_get_sym_when_links_include(symbol, link_method)
    EOL::Solr::DataObjects.should_receive(:unique_link_type_ids).and_return([LinkType.send(link_method).id])
    @details.resources_links.should include(symbol)
  end

  # obnoxious but true: we need a set of articles in various languages.
  before(:all) do
    load_foundation_cache
    @taxon_concept = TaxonConcept.gen # Doesn't need to be anything fancy, here.
    @native_entry = HierarchyEntry.gen(taxon_concept: @taxon_concept)
    @entry = HierarchyEntry.gen
    @user = User.gen
  end

  before(:each) do # NOTE - we want these 'pristine' for each test, because values get cached.
    @details = TaxonDetails.new(@taxon_concept, @user)
    @details_with_entry = TaxonDetails.new(@taxon_concept, @user, @entry)
  end

  it 'should know when it does NOT have articles in other languages' do
    @details.should_receive(:count_by_language).and_return({})
    @details.articles_in_other_languages?.should_not be_true
  end

  it 'should know when it has articles in other languages' do
    @details.should_receive(:count_by_language).and_return({whatever: 1})
    @details.articles_in_other_languages?.should be_true
  end

  # This looks more complicated than it is. It's actually pretty simple, if you read through it.
  it 'should have a count by language of approved languages (only)' do
    english_article = DataObject.gen(language: Language.first)
    english_article.stub(:approved_language?).and_return(true)
    bad_article = DataObject.gen(language: Language.last)
    bad_article.stub(:approved_language?).and_return(false)
    articles = [english_article, bad_article]
    @taxon_concept.should_receive(:text_for_user).and_return([english_article])
    DataObject.should_receive(:preload_associations).with([english_article], :language).and_return([english_article])
    @details.count_by_language.has_key?(Language.first).should be_true
    @details.count_by_language[Language.first].should == 1
    @details.count_by_language.has_key?(Language.last).should_not be_true
  end

  it 'should think there is a thumbnail if there is an image with a 260_190 version' do
    img = DataObject.gen
    img.should_receive(:thumb_or_object).with('260_190').and_return('yup')
    @details.should_receive(:image).at_least(1).times.and_return(img)
    @details.thumb?.should be_true
  end

  it 'should think there is NO thumbnail if there is an image WITHOUT a 260_190 version' do
    img = DataObject.gen
    img.should_receive(:thumb_or_object).with('260_190').and_return(nil)
    @details.should_receive(:image).at_least(1).times.and_return(img)
    @details.thumb?.should_not be_true
  end

  it 'should return the 260x190 thumbnail' do
    img = DataObject.gen
    img.should_receive(:thumb_or_object).with('260_190').and_return('howdy')
    @details.should_receive(:image).at_least(1).times.and_return(img)
    @details.thumb.should == 'howdy'
  end

  it 'should know if there are any toc_items if there are toc_roots' do
    @details.should_receive(:toc_roots).and_return('sure')
    @details.toc_items?.should be_true
  end

  it 'should know there are not any toc_items when there are no toc_roots' do
    @details.should_receive(:toc_roots).and_return([])
    @details.toc_items?.should_not be_true
  end

  # This is pretty ugly, but it's hard to test block code, yeah?
  it '#each_toc_item should iterate through the root toc items with its content' do
    first_toc_item = TocItem.gen
    first_toc_item.should_receive(:is_child?).and_return(false)
    first_content  = DataObject.gen
    first_content.should_receive(:toc_items).at_least(1).times.and_return([first_toc_item])
    child_toc_item = TocItem.gen
    child_toc_item.should_receive(:is_child?).and_return(true)
    child_content  = DataObject.gen
    child_content.should_receive(:toc_items).at_least(1).times.and_return([child_toc_item])
    second_toc_item = TocItem.gen
    second_toc_item.should_receive(:is_child?).and_return(false)
    second_content  = DataObject.gen
    second_content.should_receive(:toc_items).at_least(1).times.and_return([second_toc_item])
    content = [first_content, child_content, second_content]
    prep_details(content)
    index = 0
    @details.each_toc_item do |item, content|
      if index == 0
        item.should == first_toc_item
        content.should == [first_content]
      elsif index == 1
        item.should == second_toc_item
        content.should == [second_content]
      end
      index += 1
    end
    index.should == 2 # Ensure there weren't more results that we didn't check
  end

  it 'should know when there are NO toc items under a node' do
    toc_item = TocItem.gen
    @details.should_receive(:toc_nest_under).with(toc_item).and_return([])
    @details.toc_items_under?(toc_item).should_not be_true
  end

  it 'should know when there are toc items under a node' do
    toc_item = TocItem.gen
    @details.should_receive(:toc_nest_under).with(toc_item).and_return([1])
    @details.toc_items_under?(toc_item).should be_true
  end

  # This is pretty ugly, but it's hard to test block code, yeah?
  it '#each_toc_item should iterate through the nested toc items with its content' do
    first_toc_item = TocItem.gen(parent_id: 0)
    first_content  = DataObject.gen
    first_content.should_receive(:toc_items).at_least(1).times.and_return([first_toc_item])
    child_toc_item = TocItem.gen(parent_id: first_toc_item.id)
    child_content  = DataObject.gen
    child_content.should_receive(:toc_items).at_least(1).times.and_return([child_toc_item])
    second_child_toc_item = TocItem.gen(parent_id: first_toc_item.id)
    second_child_content  = DataObject.gen
    second_child_content.should_receive(:toc_items).at_least(1).times.and_return([second_child_toc_item])
    root_toc_item = TocItem.gen
    root_content  = DataObject.gen
    root_content.should_receive(:toc_items).at_least(1).times.and_return([root_toc_item])
    content = [first_content, child_content, second_child_content, root_content]
    prep_details(content)
    index = 0
    @details.each_nested_toc_item(first_toc_item) do |item, content|
      if index == 0
        item.should == child_toc_item
        content.should == [child_content]
      elsif index == 1
        item.should == second_child_toc_item
        content.should == [second_child_content]
      end
      index += 1
    end
    index.should == 2 # Ensure there weren't more results that we didn't check
  end

  it '#resources_links should always include partner links, by default' do
    @details.resources_links.should include(:partner_links)
  end

  it '#resources_links should include identification_resources if toc includes them' do
    should_get_sym_when_toc_includes(:identification_resources, :identification_resources)
  end

  it '#resources_links should include citizen_science if toc includes them' do
    should_get_sym_when_toc_includes(:citizen_science, :citizen_science)
  end

  it '#resources_links should include citizen_science_links if toc includes them' do
    should_get_sym_when_toc_includes(:citizen_science, :citizen_science_links)
  end

  it '#resources_links should include education if toc includes them' do
    should_get_sym_when_toc_includes(:education, :education_for_resources_tab)
  end

  it '#resources_links should include biomedical_terms if TC has a ligercat entry' do
    @taxon_concept.should_receive(:has_ligercat_entry?).and_return(true)
    @details.resources_links.should include(:biomedical_terms)
  end

  it '#resources_links should include nucleotide_sequences if TC has nucleotide_sequences_hierarchy_entry_for_taxon' do
    @taxon_concept.should_receive(:nucleotide_sequences_hierarchy_entry_for_taxon).and_return(true)
    @details.resources_links.should include(:nucleotide_sequences)
  end

  it '#resources_links should include news_and_event_links when it incudes news link_types' do
    should_get_sym_when_links_include(:news_and_event_links, :news)
  end

  it '#resources_links should include news_and_event_links when it incudes blog link_types' do
    should_get_sym_when_links_include(:news_and_event_links, :blog)
  end

  it '#resources_links should include related_organizations when it incudes organization link_types' do
    should_get_sym_when_links_include(:related_organizations, :organization)
  end

  it '#resources_links should include multimedia_links when it incudes multimedia link_types' do
    should_get_sym_when_links_include(:multimedia_links, :multimedia)
  end

  it '#literature_references_links should be blank by default' do
    @details.literature_references_links.should == []
  end

  it '#literature_references_links should include literature_references if there is a literature_references_for the TC' do
    Ref.should_receive(:literature_references_for?).with(@taxon_concept.id).and_return(true)
    @details.literature_references_links.should include(:literature_references)
  end

  it '#literature_references_links should include literature_links when it incudes paper link_types' do
    EOL::Solr::DataObjects.should_receive(:unique_link_type_ids).and_return([LinkType.paper.id])
    @details.literature_references_links.should include(:literature_links)
  end

end
