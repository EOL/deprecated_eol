require File.dirname(__FILE__) + '/../spec_helper'

def build_secondary_iucn_hierarchy_and_resource
  Agent.iucn.user ||= User.gen(:agent => Agent.iucn)
  if Agent.iucn.user.content_partner.blank?
    Agent.iucn.user.content_partners << ContentPartner.gen(:user => Agent.iucn.user)
  end
  another_iucn_resource  = Resource.gen(:title  => 'Another IUCN', :content_partner => Agent.iucn.user.content_partners.first)
  another_iucn_hierarchy = Hierarchy.gen(:label => 'Another IUCN')
  return [another_iucn_hierarchy, another_iucn_resource]
end

describe TaxonConcept do

  # Why am I loading scenarios in a model spec?  ...Because TaxonConcept is unlike other models: there is
  # really nothing to it: just an ID and a wee bit of ancillary data. At the same time, TC is *so* vital to
  # everything we do, that I wanted to construct tests that really jog the model through all of its
  # relationships.
  #
  # If you want to think of this as more of a "black-box" test, that's fine.  I chose to put it in the
  # models directory because, well, it isn't testing a website, and it IS testing a *model*, so it seemed a
  # "better" fit here, even if it isn't perfect.

  before :all do
    truncate_all_tables
    load_scenario_with_caching(:testy)
    @testy = EOL::TestInfo.load('testy')
    @overview            = @testy[:overview]
    @overview_text       = @testy[:overview_text]
    @brief_summary_text  = @testy[:brief_summary_text]
    @toc_item_2          = @testy[:toc_item_2]
    @toc_item_3          = @testy[:toc_item_3]
    @canonical_form      = @testy[:canonical_form]
    @attribution         = @testy[:attribution]
    @common_name         = @testy[:common_name]
    @scientific_name     = @testy[:scientific_name]
    @italicized          = @testy[:italicized]
    @gbif_map_id         = @testy[:gbif_map_id]
    @iucn_status         = @testy[:iucn_status]
    @image_unknown_trust = @testy[:image_unknown_trust]
    @image_untrusted     = @testy[:image_untrusted]
    @video_1_text        = @testy[:video_1_text]
    @video_2_text        = @testy[:video_2_text]
    @video_3_text        = @testy[:video_3_text]
    @comment_1           = @testy[:comment_1]
    @comment_bad         = @testy[:comment_bad]
    @comment_2           = @testy[:comment_2]
    @id                  = @testy[:id]
    @taxon_concept       = @testy[:taxon_concept]
    @curator             = @testy[:curator]
    @user                = @testy[:user]
    @tcn_count           = @testy[:tcn_count]
    @syn_count           = @testy[:syn_count]
    @name_count          = @testy[:name_count]
    @name_string         = @testy[:name_string]
    @agent               = @testy[:agent]
    @synonym             = @testy[:synonym]
    @name                = @testy[:name]
    @tcn                 = @testy[:tcn]
    @syn1                = @testy[:syn1]
    @tcn1                = @testy[:tcn1]
    @name_obj            = @testy[:name_obj]
    @syn2                = @testy[:syn2]
    @tcn2                = @testy[:tcn2]
    @good_title          = @testy[:good_title]
    @tc_bad_title        = @testy[:taxon_concept_with_bad_title]
    @tc_with_no_common_names = @testy[:taxon_concept_with_no_common_names]
    @empty_taxon_concept = @testy[:empty_taxon_concept]
    @bad_iucn_tc         = @testy[:taxon_concept_with_unpublished_iucn]
    @child1              = @testy[:child1]
    @child2              = @testy[:child2]
    @sub_child           = @testy[:sub_child]
    
    @taxon_media_parameters = {}
    @taxon_media_parameters[:per_page] = 100
    @taxon_media_parameters[:data_type_ids] = DataType.image_type_ids + DataType.video_type_ids + DataType.sound_type_ids
    @taxon_media_parameters[:return_hierarchically_aggregated_objects] = true
    
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  end

  it 'should capitalize the title (even if the name starts with a quote)' do
    @tc_bad_title.title.should =~ /#{@good_title}/
  end

  it 'should have curators' do
    @taxon_concept.curators.map(&:id).should include(@curator.id)
  end

  it 'should have a scientific name (italicized for species)' do
    @taxon_concept.scientific_name.should == @italicized
  end

  it 'should have a common name' do
    @taxon_concept.common_name.should == @common_name
  end

  it 'should show the common name from the current users language' do
    lang = Language.gen_if_not_exists(:label => 'Ancient Egyptian')
    user = User.gen(:language => lang)
    str  = 'Frebblebup'
    @taxon_concept.add_common_name_synonym(str, :agent => user.agent, :language => lang)
    @taxon_concept.current_user = user
    @taxon_concept.common_name.should == str
  end

  it 'should let you get/set the current user' do
    user = User.gen
    @taxon_concept.current_user = user
    @taxon_concept.current_user.should == user
    @taxon_concept.current_user = nil
  end

  it 'should have a default IUCN conservation status of "Not evaluated"' do
    @empty_taxon_concept.iucn_conservation_status.should match(/not evaluated/i)
  end

  it 'should have an IUCN conservation status' do
    @taxon_concept.iucn_conservation_status.should == @iucn_status
  end

  it 'should have only one IUCN conservation status when there could have been many (doesnt matter which)' do
    @taxon_concept = TaxonConcept.find(@taxon_concept.id)
    he1 = build_iucn_entry(@taxon_concept, Factory.next(:iucn))
    he2 = build_iucn_entry(@taxon_concept, Factory.next(:iucn))
    result = @taxon_concept.iucn
    result.should be_an_instance_of DataObject # (not an Array, mind you.)
    he1.delete
    he2.delete
  end

  it 'should not use an unpublished IUCN status' do
    @bad_iucn_tc.iucn_conservation_status.should match(/not evaluated/i)
  end

  it 'should be able to list its ancestors (by convention, ending with itself)' do
    he = @taxon_concept.entry
    kingdom = HierarchyEntry.gen(:hierarchy => he.hierarchy, :parent_id => 0)
    phylum = HierarchyEntry.gen(:hierarchy => he.hierarchy, :parent_id => kingdom.id)
    order = HierarchyEntry.gen(:hierarchy => he.hierarchy, :parent_id => phylum.id)
    he.parent_id = order.id
    he.save
    make_all_nested_sets
    flatten_hierarchies
    @taxon_concept.reload
    @taxon_concept.ancestors.map(&:id).should == [kingdom.taxon_concept_id, phylum.taxon_concept_id, order.taxon_concept_id, @taxon_concept.id]
  end

  it 'should be able to list its children (NOT descendants, JUST children--animalia would be a disaster!)' do
    @taxon_concept.children.map(&:id).should only_include @child1.id, @child2.id
    @taxon_concept.children.map(&:id).should_not include(@sub_child.id)
  end

  it 'should find its GBIF map ID' do
    @taxon_concept.gbif_map_id.should == @gbif_map_id
  end

  it 'should be able to show videos' do
    @taxon_concept.data_objects.select{ |d| d.is_video? }.should_not be_nil
    @taxon_concept.data_objects.select{ |d| d.is_video? }.map(&:description).should only_include @video_1_text, @video_2_text, @video_3_text
  end

  it 'should have visible comments that don\'t show invisible comments' do
    user = User.gen
    @taxon_concept.comments.find_all {|comment| comment.visible? }.should_not be_nil
    @taxon_concept.comments.find_all {|comment| comment.visible? }.map(&:body).should == [@comment_1, @comment_2] # Order DOES matter, now.
  end

  it 'should be able to show a table of contents' do
    # Tricky, tricky. See, we add special things to the TOC like "Common Names" and "Search the Web", when they are
    # appropriate.  I could test for those here, but that seems the perview of TocItem.  So, I'm only checking the
    # first three elements:
    user = User.gen
    text = @taxon_concept.details_text_for_user(user)
    toc_items_to_show = @taxon_concept.table_of_contents_for_text(text)
    toc_items_to_show[0..3].should == [@overview, @testy[:brief_summary], @toc_item_2, @toc_item_3]
  end

  it 'should have images and videos in #media' do
    @taxon_concept.data_objects_from_solr(@taxon_media_parameters).map(&:description).should include(@video_1_text)
    @taxon_concept.data_objects_from_solr(@taxon_media_parameters).map(&:object_cache_url).should include(@testy[:image_1])
  end

  it 'should show its untrusted images, by default' do
    @taxon_concept.current_user = nil
    @taxon_concept.images_from_solr(100).map(&:object_cache_url).should include(@image_unknown_trust)
  end

  describe '#overview_text_for_user' do
    before :all do
      if @user_for_overview_text = User.find_by_username('overview_text_for_user')
        @overview_text_for_user = @taxon_concept.overview_text_for_user(@user_for_overview_text)
      else
        flatten_hierarchies
        @user_for_overview_text = User.gen(:username => 'overview_text_for_user')
        @overview_text_for_user = @taxon_concept.overview_text_for_user(@user_for_overview_text)
        parent_he = @taxon_concept.published_hierarchy_entries.first.parent
        CuratedDataObjectsHierarchyEntry.new(:data_object => @overview_text_for_user,
                                             :hierarchy_entry => parent_he,
                                             :visibility => Visibility.invisible,
                                             :vetted => Vetted.untrusted,
                                             :user_id => 1).save
        @overview_text_for_user.update_solr_index
      end
    end
    it 'should return single text object' do
      @overview_text_for_user.should be_a(DataObject)
      @overview_text_for_user.is_text?.should be_true
    end
    it 'should only return data object with TocItem.brief_summary, TocItem.comprehensive_description, or TocItem.distribution' do
      @overview_text_for_user.toc_items.first.should == TocItem.brief_summary
      @overview_text_for_user.description.should == @brief_summary_text

      dato_id = @overview_text_for_user.id
      @overview_text_for_user.toc_items = [TocItem.comprehensive_description]
      @overview_text_for_user.save
      @overview_text_for_user.update_solr_index
      @overview_text_for_user = @taxon_concept.overview_text_for_user(@user_for_overview_text)
      @overview_text_for_user.id.should == dato_id
      @overview_text_for_user.toc_items.first.should == TocItem.comprehensive_description

      @overview_text_for_user.toc_items = [TocItem.distribution]
      @overview_text_for_user.save
      @overview_text_for_user.update_solr_index
      @overview_text_for_user = @taxon_concept.overview_text_for_user(@user_for_overview_text)
      @overview_text_for_user.id.should == dato_id
      @overview_text_for_user.toc_items.first.should == TocItem.distribution

      @overview_text_for_user.toc_items = [TocItem.overview]
      @overview_text_for_user.save
      @overview_text_for_user.update_solr_index
      @overview_text_for_user = @taxon_concept.overview_text_for_user(@user_for_overview_text)
      @overview_text_for_user.should be_nil

      @overview_text_for_user = DataObject.find(dato_id, :include => :toc_items)
      @overview_text_for_user.toc_items = [TocItem.brief_summary]
      @overview_text_for_user.save
      @overview_text_for_user.update_solr_index
      @overview_text_for_user = @taxon_concept.overview_text_for_user(@user_for_overview_text)
      @overview_text_for_user.id.should == dato_id
      @overview_text_for_user.toc_items.first.should == TocItem.brief_summary
    end
    it 'should not return data objects of descendants' do
      parent_tc = @taxon_concept.published_hierarchy_entries.first.parent.taxon_concept
      overview = parent_tc.overview_text_for_user(@user_for_overview_text)
      overview.should be_nil
    end
    it 'should not return data objects with hidden associations to taxon concept unless user is a curator' do
      tc = @taxon_concept.published_hierarchy_entries.first.parent.taxon_concept
      overview = tc.overview_text_for_user(@user_for_overview_text)
      overview.should be_nil
      overview = tc.overview_text_for_user(@curator)
      overview.should == @overview_text_for_user
    end
  end

  it 'should return available text objects for given toc items in order of preference and rating' do
    given_toc_items = [@testy[:toc_item_2], @testy[:brief_summary]]
    results = @taxon_concept.data_objects_from_solr(:data_type_ids => [ DataType.text.id] , :toc_ids => given_toc_items.collect(&:id))
    results.each do |text|
      text.data_type_id.should == DataType.text.id
      diff = text.toc_items - given_toc_items
      diff.should be_empty
    end
  end

  it 'should return a subset of text objects for each given toc item if option limit is set' do
    given_toc_items = [@testy[:toc_item_2], @testy[:toc_item_3]]
    results = @taxon_concept.data_objects_from_solr(:data_type_ids => [ DataType.text.id], :toc_ids => given_toc_items.collect(&:id))
    results.count.should == 3
    results = @taxon_concept.data_objects_from_solr(:data_type_ids => [ DataType.text.id], :toc_ids => given_toc_items.collect(&:id), :per_page => 2)
    results.count.should == 2
  end

  it "should have common names" do
    @taxon_concept.all_common_names.length.should > 0
  end

  it "should not have common names" do
    @tc_with_no_common_names.all_common_names.length.should == 0
  end

  it "should be able to filter common_names by taxon_concept or hierarchy_entry" do
    # by taxon_concept
    common_names = @taxon_concept.common_names()
    common_names.count.should > 0
    # by hierarchy_entry
    hierarchy_entry = @taxon_concept.published_browsable_hierarchy_entries.first
    taxon_concept_name = TaxonConceptName.gen(:vern => 1, :source_hierarchy_entry_id => hierarchy_entry.id, :taxon_concept_id => @taxon_concept.id)
    common_names = @taxon_concept.common_names(:hierarchy_entry_id => hierarchy_entry.id)
    common_names.count.should > 0
  end

  it "should be able to filter related_names by taxon_concept or hierarchy_entry" do
    # by taxon_concept
    related_names = TaxonConcept.related_names(:taxon_concept_id => @taxon_concept.id)
    related_names.class.should == Hash
    # by hierarchy_entry
    hierarchy_entry = @taxon_concept.published_browsable_hierarchy_entries.first
    related_names = TaxonConcept.related_names(:hierarchy_entry_id => hierarchy_entry.id)
    related_names.class.should == Hash
  end

  it "should be able to filter synonyms by taxon_concept or hierarchy_entry" do
    # by taxon_concept
    hierarchy_entries = @taxon_concept.published_browsable_hierarchy_entries
    for he in hierarchy_entries
      he.scientific_synonyms.class.should == Array
    end
    # by hierarchy_entry
    hierarchy_entries = @taxon_concept.published_hierarchy_entries
    for he in hierarchy_entries
      he.scientific_synonyms.class.should == Array
    end
  end

  it 'should not return untrusted images to non-curators' do
    @taxon_concept.reload
    trusted   = Vetted.trusted.id
    unknown   = Vetted.unknown.id
    @taxon_concept.data_objects_from_solr(@taxon_media_parameters.merge(:data_type_ids => DataType.image_type_ids)).map { |item|
      item_vetted = item.vetted_by_taxon_concept(@taxon_concept, :find_best => true)
      item_vetted_id = item_vetted.id unless item_vetted.nil?
      item_vetted_id
    }.uniq.should == [trusted, unknown]
  end
  
  it 'should return media sorted by trusted, unknown, untrusted' do
    @taxon_concept.reload
    trusted   = Vetted.trusted.id
    unknown   = Vetted.unknown.id
    untrusted = Vetted.untrusted.id
    @taxon_concept.data_objects_from_solr(@taxon_media_parameters.merge(:data_type_ids => DataType.image_type_ids, :vetted_types => ['trusted', 'unreviewed', 'untrusted'])).map { |item|
      item_vetted = item.vetted_by_taxon_concept(@taxon_concept, :find_best => true)
      item_vetted_id = item_vetted.id unless item_vetted.nil?
      item_vetted_id
    }.uniq.should == [trusted, unknown, untrusted]
  end
  

  it 'should sort the vetted images by data rating' do
    @taxon_concept.current_user = @user
    ratings = @taxon_concept.images_from_solr(100).select { |item|
      item_vetted = item.vetted_by_taxon_concept(@taxon_concept, :find_best => true)
      item_vetted_id = item_vetted.id unless item_vetted.nil?
      item_vetted_id == Vetted.trusted.id
    }.map(&:data_rating)
    ratings.should == ratings.sort.reverse
  end

  it 'should create a common name as a preferred common name, if there are no other common names for the taxon' do
    tc = @tc_with_no_common_names # TODO - this depends on the order of tests.
    agent = Agent.last
    tc.add_common_name_synonym('A name', :agent => agent, :language => Language.english)
    tc.quick_common_name.should == "A name"
    tc.add_common_name_synonym("Another name", :agent => agent, :language => Language.english)
    tc.quick_common_name.should == "A name"
  end

  it 'should include the LigerCat TocItem when the TaxonConcept has one'

  it 'should NOT include the LigerCat TocItem when the TaxonConcept does NOT have one'

  it 'should have a canonical form' do
    @taxon_concept.entry.name.canonical_form.string.should == @canonical_form
  end

  it 'should cite a vetted source for the page when there are both vetted and unvetted sources' do
    h_vetted = Hierarchy.gen()
    h_unvetted = Hierarchy.gen()
    concept = TaxonConcept.gen(:published => 1, :vetted => Vetted.trusted)
    concept.entry.should be_nil

    # adding an unvetted name and testing
    unvetted_name = Name.gen(:canonical_form => cf = CanonicalForm.gen(:string => 'Annnvettedname'),
                      :string => 'Annnvettedname',
                      :italicized => '<i>Annnvettedname</i>')
    he_unvetted = build_hierarchy_entry(0, concept, unvetted_name,
                                :hierarchy => h_unvetted,
                                :vetted_id => Vetted.unknown.id,
                                :published => 1)
    concept = TaxonConcept.find(concept.id) # cheating so I can flush all the instance variables
    concept.entry.should_not be_nil
    concept.entry.id.should == he_unvetted.id
    concept.entry.name.string.should == unvetted_name.string

    # adding a vetted name and testing
    vetted_name = Name.gen(:canonical_form => cf = CanonicalForm.gen(:string => 'Avettedname'),
                      :string => 'Avettedname',
                      :italicized => '<i>Avettedname</i>')
    he_vetted = build_hierarchy_entry(0, concept, vetted_name,
                                :hierarchy => h_vetted,
                                :vetted_id => Vetted.trusted.id,
                                :published => 1)
    concept = TaxonConcept.find(concept.id) # cheating so I can flush all the instance variables
    concept.preferred_entry = nil
    concept.entry.id.should == he_vetted.id
    concept.entry.name.string.should == vetted_name.string

    # adding another unvetted name to test the vetted name remains
    another_unvetted_name = Name.gen(:canonical_form => cf = CanonicalForm.gen(:string => 'Anotherunvettedname'),
                      :string => 'Anotherunvettedname',
                      :italicized => '<i>Anotherunvettedname</i>')
    he_anotherunvetted = build_hierarchy_entry(0, concept, another_unvetted_name,
                                :hierarchy => h_vetted,
                                :vetted_id => Vetted.unknown.id,
                                :published => 1)
    concept = TaxonConcept.find(concept.id) # cheating so I can flush all the instance variables
    concept.entry.id.should == he_vetted.id
    concept.entry.name.string.should == vetted_name.string

    # now remove the vetted hierarchy entry and make sure the first entry is the chosen one
    he_vetted.destroy
    concept = TaxonConcept.find(concept.id) # cheating so I can flush all the instance variables
    concept.entry.id.should == he_unvetted.id
    concept.entry.name.string.should == unvetted_name.string
  end

  it "add common name should increase name count, taxon name count, synonym count" do
    tcn_count = TaxonConceptName.count
    syn_count = Synonym.count
    name_count = Name.count

    @taxon_concept.add_common_name_synonym('any name', :agent => @agent, :language => Language.english)

    TaxonConceptName.count.should == tcn_count + 1
    Synonym.count.should == syn_count + 1
    Name.count.should == name_count + 1
  end

  it "add common name should mark first created name for a language as preferred automatically" do
    language = Language.gen_if_not_exists(:label => "Russian")
    weird_name = "Саблезубая сосиска"
    s = @taxon_concept.add_common_name_synonym(weird_name, :agent => @agent, :language => language)
    TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(@taxon_concept, language).size.should == 1
    TaxonConceptName.find_by_synonym_id(s.id).preferred?.should be_true
    weird_name = "Голый землекоп"
    s = @taxon_concept.add_common_name_synonym(weird_name, :agent => @agent, :language => language)
    TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(@taxon_concept, language).size.should == 2
    TaxonConceptName.find_by_synonym_id(s.id).preferred?.should be_false
  end

  it "add common name should not mark first created name as preferred for unknown language" do
    language = Language.unknown
    weird_name = "Саблезубая сосискаasdfasd"
    s = @taxon_concept.add_common_name_synonym(weird_name, :agent => @agent, :language => language)
    TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(@taxon_concept, language).size.should == 1
    TaxonConceptName.find_by_synonym_id(s.id).preferred?.should be_false
  end

  it "add common name should create new name object" do
    @name.class.should == Name
    @name.string.should == @name_string
  end

  it "add common name should create synonym" do
    @synonym.class.should == Synonym
    @synonym.name.should == @name
    @synonym.agents.uniq.should == [@curator.agent]
  end

  it "add common name should create taxon_concept_name" do
    @tcn.should_not be_nil
  end

  it "add common name should be able to create a common name with the same name string but different language" do
    tcn_count = TaxonConceptName.count
    syn_count = Synonym.count
    name_count = Name.count

    syn = @taxon_concept.add_common_name_synonym(@name_string, :agent => Agent.find(@curator.agent_id), :language => Language.gen_if_not_exists(:label => "French"))
    TaxonConceptName.count.should == tcn_count + 1
    Synonym.count.should == syn_count + 1
    Name.count.should == name_count  # name wasn't new
  end

  it "delete common name should delete a common name" do
    tcn_count = TaxonConceptName.count
    syn_count = Synonym.count
    name_count = Name.count

    @taxon_concept.delete_common_name(@tcn)
    TaxonConceptName.count.should < tcn_count
    Synonym.count.should < syn_count
    Name.count.should == name_count  # name is not deleted
  end

  it "delete common name should delete preferred common names, should mark last common name for a language as preferred" do
    # remove all existing English common names
    TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(@testy[:empty_taxon_concept], Language.english).each do |tcn|
      tcn.delete
    end

    # first one should go in as preferred
    first_syn = @testy[:empty_taxon_concept].add_common_name_synonym('First english name', :agent => @agent, :language => Language.english)
    first_tcn = TaxonConceptName.find_by_synonym_id(first_syn.id)
    first_tcn.preferred?.should be_true

    # second should not be preferred
    second_syn = @testy[:empty_taxon_concept].add_common_name_synonym('Second english name', :agent => @agent, :language => Language.english)
    second_tcn = TaxonConceptName.find_by_synonym_id(second_syn.id)
    second_tcn.preferred?.should be_false

    # after removing the first, the last one should change to preferred
    @testy[:empty_taxon_concept].delete_common_name(first_tcn)
    second_tcn.reload
    second_tcn.preferred?.should be_true
  end

  it 'should untrust all synonyms and TCNs related to a TC when untrusted' do
    # Make them all "trusted" first:
    [@syn1, @syn2, @tcn1, @tcn2].each {|obj| obj.update_attributes!(:vetted => Vetted.trusted) }
    @taxon_concept.vet_common_name(:vetted => Vetted.untrusted, :language_id => Language.english.id, :name_id => @name_obj.id)
    @syn1.reload.vetted_id.should == Vetted.untrusted.id
    @syn2.reload.vetted_id.should == Vetted.untrusted.id
    @tcn1.reload.vetted_id.should == Vetted.untrusted.id
    @tcn2.reload.vetted_id.should == Vetted.untrusted.id
  end

  it 'should "unreview" all synonyms and TCNs related to a TC when unreviewed' do
    # Make them all "trusted" first:
    [@syn1, @syn2, @tcn1, @tcn2].each {|obj| obj.update_attributes!(:vetted => Vetted.trusted) }
    @taxon_concept.vet_common_name(:vetted => Vetted.unknown, :language_id => Language.english.id, :name_id => @name_obj.id)
    @syn1.reload.vetted_id.should == Vetted.unknown.id
    @syn2.reload.vetted_id.should == Vetted.unknown.id
    @tcn1.reload.vetted_id.should == Vetted.unknown.id
    @tcn2.reload.vetted_id.should == Vetted.unknown.id
  end

  it 'should trust all synonyms and TCNs related to a TC when trusted' do
    # Make them all "unknown" first:
    [@syn1, @syn2, @tcn1, @tcn2].each {|obj| obj.update_attributes!(:vetted => Vetted.unknown) }
    @taxon_concept.vet_common_name(:vetted => Vetted.trusted, :language_id => Language.english.id, :name_id => @name_obj.id)
    @syn1.reload.vetted_id.should == Vetted.trusted.id
    @syn2.reload.vetted_id.should == Vetted.trusted.id
    @tcn1.reload.vetted_id.should == Vetted.trusted.id
    @tcn2.reload.vetted_id.should == Vetted.trusted.id
  end

  it 'should inappropriate all synonyms and TCNs related to a TC when inappropriated' do
    # Make them all "unknown" first:
    [@syn1, @syn2, @tcn1, @tcn2].each {|obj| obj.update_attributes!(:vetted => Vetted.unknown) }
    @taxon_concept.vet_common_name(:vetted => Vetted.inappropriate, :language_id => Language.english.id, :name_id => @name_obj.id)
    @syn1.reload.vetted_id.should == Vetted.inappropriate.id
    @syn2.reload.vetted_id.should == Vetted.inappropriate.id
    @tcn1.reload.vetted_id.should == Vetted.inappropriate.id
    @tcn2.reload.vetted_id.should == Vetted.inappropriate.id
  end

  it 'should have an activity log' do
    tc = TaxonConcept.gen
    tc.respond_to?(:activity_log).should be_true
    tc.activity_log.should be_a WillPaginate::Collection
  end

  it 'should rely on collection for sorting #top_collections' do
    tc = TaxonConcept.gen
    col1 = Collection.gen
    col2 = Collection.gen
    tc.should_receive(:collections).and_return([col1, col2])
    col1.should_receive(:relevance).and_return(1)
    col2.should_receive(:relevance).and_return(2)
    tc.top_collections
  end

  it 'should list communites in the proper order - most number of members show first' do
    community1 = Community.gen()
    community2 = Community.gen()
    user1 = User.gen()
    user2 = User.gen()
    user3 = User.gen()
    member1 = Member.gen(:community => community2, :user => user1)
    member2 = Member.gen(:community => community2, :user => user2)
    member3 = Member.gen(:community => community1, :user => user3)
    collection1 = community1.collections.first
    collection2 = community2.collections.first
    tc = TaxonConcept.gen
    coll_item1 = CollectionItem.gen(:object_type => "TaxonConcept", :object_id => tc.id, :collection => collection1)
    coll_item2 = CollectionItem.gen(:object_type => "TaxonConcept", :object_id => tc.id, :collection => collection2)
    tc.collection_items[1].collection.communities.include?(community2).should be_true
    tc.top_communities[0].name.should == community2.name
    tc.top_communities[1].name.should == community1.name
  end

  it 'should return an exemplar' do
    if exemplar_exists = @taxon_concept.taxon_concept_exemplar_image
      exemplar_exists.destroy
    end
    image = DataObject.gen(:data_type_id => DataType.image.id, :data_rating => 0.1, :published => 1)
    dohe = DataObjectsHierarchyEntry.gen(:data_object => image, :hierarchy_entry => @taxon_concept.published_hierarchy_entries.first)
    TaxonConceptExemplarImage.gen(:taxon_concept => @taxon_concept, :data_object => image)
    @taxon_concept.reload
    @taxon_concept.exemplar_or_best_image_from_solr.id.should == image.id
  end
  
  it 'should not return unpublished exemplar image' do
    if exemplar_exists = @taxon_concept.taxon_concept_exemplar_image
      exemplar_exists.destroy
    end
    image = DataObject.gen(:data_type_id => DataType.image.id, :data_rating => 0.1, :published => 0)
    dohe = DataObjectsHierarchyEntry.gen(:data_object => image, :hierarchy_entry => @taxon_concept.published_hierarchy_entries.first)
    TaxonConceptExemplarImage.gen(:taxon_concept => @taxon_concept, :data_object => image)
    @taxon_concept.reload
    @taxon_concept.exemplar_or_best_image_from_solr.id.should_not == image.id
  end

  it 'should not return hidden exemplar image' do
    if exemplar_exists = @taxon_concept.taxon_concept_exemplar_image
      exemplar_exists.destroy
    end
    image = DataObject.gen(:data_type_id => DataType.image.id, :data_rating => 0.1, :published => 0)
    dohe = DataObjectsHierarchyEntry.gen(:data_object => image, :hierarchy_entry => @taxon_concept.published_hierarchy_entries.first, :visibility => Visibility.invisible)
    TaxonConceptExemplarImage.gen(:taxon_concept => @taxon_concept, :data_object => image)
    @taxon_concept.reload
    @taxon_concept.exemplar_or_best_image_from_solr.id.should_not == image.id
  end

  it 'should show details text with no language only to users in the default language' do
    user = User.gen(:language => Language.default)
    best_text = @taxon_concept.details_text_for_user(user).first
    best_text.language_id.should == Language.default.id
    best_text.language_id = 0
    best_text.data_rating = 5
    best_text.save
    best_text.update_solr_index
    new_best_text = @taxon_concept.details_text_for_user(user).first
    new_best_text.language_id.should == 0
    new_best_text.id.should == best_text.id
    
    user = User.gen(:language => Language.find_by_iso_639_1('fr'))
    new_best_text = @taxon_concept.overview_text_for_user(user)
    new_best_text.should == nil
    
    # cleaning up
    best_text.language_id = Language.default.id
    best_text.save
    best_text.update_solr_index
  end

  it 'should show overview text with no language only to users in the default language' do
    user = User.gen(:language => Language.default)
    best_text = @taxon_concept.overview_text_for_user(user)
    best_text.language_id.should == Language.default.id
    best_text.language_id = 0
    best_text.data_rating = 5
    best_text.save
    best_text.update_solr_index
    new_best_text = @taxon_concept.overview_text_for_user(user)
    new_best_text.language_id.should == 0
    new_best_text.id.should == best_text.id
    
    user = User.gen(:language => Language.find_by_iso_639_1('fr'))
    new_best_text = @taxon_concept.overview_text_for_user(user)
    new_best_text.should == nil
    
    # cleaning up
    best_text.language_id = Language.default.id
    best_text.save
    best_text.update_solr_index
  end

  it 'should use the name from the specified hierarchy' do
    tc = TaxonConcept.gen
    name1 = Name.gen(:string => "Name1")
    he1 = HierarchyEntry.gen(:taxon_concept => tc, :name => name1, :hierarchy => Hierarchy.gen)
    name2 = Name.gen(:string => "Name2")
    he2 = HierarchyEntry.gen(:taxon_concept => tc, :name => name2, :hierarchy => Hierarchy.gen)
    
    tc.entry.should == he1
    tc.title.should == he1.name.string
    tc = TaxonConcept.find(tc.id)
    
    tc.entry(he1.hierarchy).should == he1
    tc.title(he1.hierarchy).should == he1.name.string
    tc = TaxonConcept.find(tc.id)
    
    tc.entry(he2.hierarchy).should == he2
    tc.title(he2.hierarchy).should == he2.name.string
    tc = TaxonConcept.find(tc.id)
    
    # now checking the default again to make sure we get the original value
    tc.entry.should == he1
    tc.title.should == he1.name.string
  end

  it 'should have a smart #entry' do
    tc = TaxonConcept.gen
    he = HierarchyEntry.last
    xpect 'which does NOT accept arguments other than a Hierarchy'
    lambda { tc.entry(he) }.should raise_error
    xpect 'which uses preferred entry if available'
    TaxonConceptPreferredEntry.create(:taxon_concept_id => tc.id, :hierarchy_entry_id => he.id)
    tcpe = TaxonConceptPreferredEntry.last
    tc.entry.should == he
    xpect 'which is a singleton'
    TaxonConceptPreferredEntry.delete(tcpe)
    tc.entry.should == he
    # TODO - there's much more going on here, but I don't have the energy:
    # xpect 'which uses published hierarchy entries first'
    # xpect 'which uses unpublished hierarchy entries if no published entries exist'
    # xpect 'which uses an HE in the specified hierarchy if available'
    # xpect 'which uses the first availble HE if the specified hierarchy has no entry availble.'
    # xpect 'which does NOT use an expired preferred_entry'
    # xpect 'which creates a preferred entry if one did not exist'
  end

  it 'should not give an error when there is no preferred_entry' do
    tc = build_taxon_concept
    lambda { tc.curator_chosen_classification }.should_not raise_error
    lambda { tc.preferred_entry.hierarchy_entry_id }.should raise_error
  end

  #
  # I'm all for pending tests, but in this case, they run SLOWLY, so it's best to comment them out:
  #

  # Medium Priority:
  #
  # it 'should be able to list whom the species is recognized by' do
  # it 'should be able to add a comment' do
  # it 'should be able to list exemplars' do
  #
  # Lower priority (at least for me!)
  #
  # it 'should know which hosts to ping' do
  # it 'should be able to set a current agent' # This is only worthwhile if we know what it should change... do
  # it 'should follow supercedure' do
  # it 'should be able to show a thumbnail' do
  # it 'should be able to show a single image' do

end
