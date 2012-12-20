# encoding: utf-8
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
    @taxon_concept       = @testy[:taxon_concept]
    @overview            = @testy[:overview]
    @overview_text       = @testy[:overview_text]
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
    @curator             = @testy[:curator]
    @user                = @testy[:user]
    @tcn_count           = @testy[:tcn_count]
    @syn_count           = @testy[:syn_count]
    @name_count          = @testy[:name_count]
    @name_string         = @testy[:name_string]
    @agent               = @testy[:agent]
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
    @tc_with_no_starting_common_names = @testy[:taxon_concept_with_no_starting_common_names]
    @empty_taxon_concept = @testy[:empty_taxon_concept]
    @bad_iucn_tc         = @testy[:taxon_concept_with_unpublished_iucn]
    @child1              = @testy[:child1]
    @child2              = @testy[:child2]
    @sub_child           = @testy[:sub_child]
    
    @taxon_concept_common_name_at_start = @taxon_concept.common_name # allows changes later if needed
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
    @taxon_concept_common_name_at_start.should == @common_name
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
    he1 = build_iucn_entry(@taxon_concept, FactoryGirl.generate(:iucn))
    he2 = build_iucn_entry(@taxon_concept, FactoryGirl.generate(:iucn))
    result = @taxon_concept.iucn
    result.should be_an_instance_of DataObject # (not an Array, mind you.)
    he1.delete
    he2.delete
  end

  it 'should not use an unpublished IUCN status' do
    @bad_iucn_tc.iucn_conservation_status.should match(/not evaluated/i)
  end

  it 'should be able to list its ancestors' do
    @testy[:species].ancestors.map(&:id).should == [@testy[:kingdom].taxon_concept_id, @testy[:phylum].taxon_concept_id, @testy[:order].taxon_concept_id]
  end

  it 'should be able to list its children (NOT descendants, JUST children--animalia would be a disaster!)' do
    @taxon_concept.children.map(&:id).should only_include [@child1.id, @child2.id]
    @taxon_concept.children.map(&:id).should_not include(@sub_child.id)
  end

  it 'should find its GBIF map ID' do
    @taxon_concept.gbif_map_id.should == @gbif_map_id
  end

  it 'should be able to show videos' do
    @taxon_concept.data_objects.select{ |d| d.is_video? }.should_not be_nil
    @taxon_concept.data_objects.select{ |d| d.is_video? }.map(&:description).should only_include [@video_1_text, @video_2_text, @video_3_text]
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
    @taxon_concept.images_from_solr(100).map {|d| DataObject.find(d).object_cache_url }.should include(@image_unknown_trust)
  end

  describe '#overview_text_for_user' do
    it 'should return single text object' do
      overview_text_for_user = @testy[:only_brief_summary].overview_text_for_user(@testy[:user])
      overview_text_for_user.should be_a(DataObject)
      overview_text_for_user.is_text?.should be_true
    end
    it 'should only return data object with TocItem.brief_summary, TocItem.comprehensive_description, or TocItem.distribution' do
      overview_text_for_user = @testy[:only_brief_summary].overview_text_for_user(@testy[:user])
      overview_text_for_user.toc_items.first.should == TocItem.brief_summary
      overview_text_for_user.description.should == @testy[:brief_summary_text]

      overview_text_for_user = @testy[:only_comprehensive_description].overview_text_for_user(@testy[:user])
      overview_text_for_user.toc_items.first.should == TocItem.comprehensive_description
      overview_text_for_user.description.should == @testy[:comprehensive_description_text]

      overview_text_for_user = @testy[:only_distribution].overview_text_for_user(@testy[:user])
      overview_text_for_user.toc_items.first.should == TocItem.distribution
      overview_text_for_user.description.should == @testy[:distribution_text]

      overview_text_for_user = @testy[:only_overview].overview_text_for_user(@testy[:user])
      overview_text_for_user.should be_nil
    end
    it 'should not return data objects of descendants' do
      parent_tc = @taxon_concept.published_hierarchy_entries.first.parent.taxon_concept
      overview = parent_tc.overview_text_for_user(@testy[:user])
      overview.should be_nil
    end
    it 'should not return data objects with hidden associations to taxon concept unless user is a curator'
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
    }.map! {|d| DataObject.find(d).data_rating }
    ratings.should == ratings.sort.reverse
  end

  it 'should create a common name as a preferred common name, if there are no other common names for the taxon' do
    tc = @tc_with_no_starting_common_names
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
    HierarchyEntry.delete(he_vetted) rescue nil # #destroy does not work with acts_as_tree, it seems.
    concept.reload
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
    @testy[:synonym].class.should == Synonym
    @testy[:synonym].name.should == @name
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

  # TODO - this isn't the best place for this test; It would be preferable to test this behavior on activity_log.
  # (Or, better still, a new TaxonConceptActivityLogReader class, but perhaps I'm getting greedy, there.)
  # ...Also, the expression of this spec is ... awful.  But I'm in a rush.
  it 'should show comments from superceded taxa' do
    @testy[:superceded_comment].log_activity_in_solr # It doesn't seem to be, by default.
    @taxon_concept.activity_log(:per_page => 500).select { |a| a["activity_log_type"] == "Comment"}.map { |c|
      c["instance"].body }.should include(@testy[:superceded_comment].body)
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
    tc = build_taxon_concept
    coll_item1 = CollectionItem.gen(:collected_item_type => "TaxonConcept", :collected_item_id => tc.id, :collection => collection1)
    coll_item2 = CollectionItem.gen(:collected_item_type => "TaxonConcept", :collected_item_id => tc.id, :collection => collection2)
    tc.collection_items[1].collection.communities.include?(community2).should be_true
    tc.top_communities[0].name.should == community2.name
    tc.top_communities[1].name.should == community1.name
  end

  it 'should return an exemplar' do
    @testy[:has_one_image].exemplar_or_best_image_from_solr.id.should == @testy[:the_one_image].id
  end
  
  it 'should not return unpublished exemplar image' do
    @testy[:has_one_unpublished_image].exemplar_or_best_image_from_solr.should be_nil
  end

  it 'should not return hidden exemplar image' do
    @testy[:has_one_hidden_image].exemplar_or_best_image_from_solr.should be_nil
  end

  it 'should show details text with no language only to users in the default language' do
    user = User.gen(:language => Language.default)
    @taxon_concept.details_text_for_user(user).first.language_id.should == Language.default.id
    best_text = @testy[:no_language_in_toc].details_text_for_user(user).first
    best_text.language_id.should == 0

    user = User.gen(:language => Language.find_by_iso_639_1('fr'))
    new_best_text = @testy[:no_language_in_toc].overview_text_for_user(user)
    new_best_text.should be_nil
  end

  it 'should show overview text with no language only to users in the default language' do
    user = User.gen(:language => Language.default)
    @taxon_concept.overview_text_for_user(user).language_id.should == Language.default.id
    new_best_text = @testy[:no_language_in_toc].overview_text_for_user(user)
    new_best_text.language_id.should == 0

    user = User.gen(:language => Language.find_by_iso_639_1('fr'))
    new_best_text = @testy[:no_language_in_toc].overview_text_for_user(user)
    new_best_text.should be_nil
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
    # 'which does NOT accept arguments other than a Hierarchy'
    lambda { tc.entry(he) }.should raise_error
    # 'which uses preferred entry if available'
    TaxonConceptPreferredEntry.create(:taxon_concept_id => tc.id, :hierarchy_entry_id => he.id)
    tcpe = TaxonConceptPreferredEntry.last
    tc.entry.should == he
    # 'which is a singleton'
    TaxonConceptPreferredEntry.delete(tcpe)
    tc.entry.should == he
    # TODO - there's much more going on here, but I don't have the energy:
    # # 'which uses published hierarchy entries first'
    # # 'which uses unpublished hierarchy entries if no published entries exist'
    # # 'which uses an HE in the specified hierarchy if available'
    # # 'which uses the first availble HE if the specified hierarchy has no entry availble.'
    # # 'which does NOT use an expired preferred_entry'
    # # 'which creates a preferred entry if one did not exist'
  end

  it 'should not give an error when there is no preferred_entry' do
    tc = build_taxon_concept
    lambda { tc.curator_chosen_classification }.should_not raise_error
    lambda { tc.preferred_entry.hierarchy_entry_id }.should raise_error
  end

  it '#published_visible_exemplar_article should return published and visible exemplar article if there is one' do
    published_visible_exemplar_article = @taxon_concept.published_visible_exemplar_article
    if published_visible_exemplar_article
      published_visible_exemplar_article.class.should == DataObject
    end
    data_object = DataObject.gen(:data_type_id => DataType.text.id, :published => 1)
    data_object.taxon_concepts = [@taxon_concept]
    DataObjectsHierarchyEntry.create(:hierarchy_entry_id => @taxon_concept.entry.id, :data_object_id => data_object.id,
                                     :vetted_id => Vetted.trusted.id, :visibility_id => Visibility.visible.id)
    TaxonConceptExemplarArticle.set_exemplar(@taxon_concept.id, data_object.id)
    @taxon_concept.reload
    published_visible_exemplar_article = @taxon_concept.published_visible_exemplar_article
    published_visible_exemplar_article.class.should == DataObject
    published_visible_exemplar_article.id.should == data_object.id
  end

  it 'should count descendants using TaxonConceptsFlattened' do
    TaxonConceptsFlattened.should_receive(:descendants_of).with(@taxon_concept.id).and_return((0..13).to_a)
    @taxon_concept.number_of_descendants.should == 14
  end

  describe '#split_classifications' do

    before(:all) do
      @exemplar = @taxon_concept.hierarchy_entries.first.id
      @entries = [@taxon_concept.hierarchy_entries.second.id]
      @max_descendants = 10
      @too_many_descendants = (0..@max_descendants).to_a
      SiteConfigurationOption.stub!(:max_curatable_descendants).and_return(@max_descendants)
    end

    before(:each) do
      TaxonClassificationsLock.delete_all
    end

    it 'should not run if locked' do
      @taxon_concept.lock_classifications
      lambda { @taxon_concept.split_classifications(@entries, :user => @user, :exemplar_id => @exemplar) }.should
        raise_error(EOL::Exceptions::ClassificationsLocked)
    end

    it 'should not run if too large' do
      lambda {
        TaxonConceptsFlattened.should_receive(:descendants_of).with(@taxon_concept.id).and_return(@too_many_descendants)
        @taxon_concept.split_classifications(@entries, :user => @user, :exemplar_id => @exemplar)
      }.should
        raise_error(EOL::Exceptions::TooManyDescendantsToCurate)
    end

    it 'should lock classifications and create a ClassificationCuration' do
      @taxon_concept.classifications_locked?.should_not be_true
      ClassificationCuration.should_receive(:create).and_return(nil)
      @taxon_concept.split_classifications(@entries, :user => @user, :exemplar_id => @exemplar) 
      @taxon_concept.reload
      @taxon_concept.classifications_locked?.should be_true
    end

  end


  describe '#merge_classifications' do

    before(:all) do
      @with = @tc_bad_title
      @exemplar = @taxon_concept.hierarchy_entries.first.id
      @entries = [@taxon_concept.hierarchy_entries.second.id]
      @max_descendants = 10
      @too_many_descendants = (0..@max_descendants).to_a
      SiteConfigurationOption.stub!(:max_curatable_descendants).and_return(@max_descendants)
    end

    before(:each) do
      TaxonClassificationsLock.delete_all
      @taxon_concept.reload
      @with.reload
    end

    it 'should not run if locked' do
      @taxon_concept.lock_classifications
      lambda { @taxon_concept.merge_classifications(@entries, :with => @with, :user => @user,
                                                    :exemplar_id => @exemplar) }.should
        raise_error(EOL::Exceptions::ClassificationsLocked)
    end

    it 'should not run if the other concept is locked' do
      @with.lock_classifications
      lambda { @taxon_concept.merge_classifications(@entries, :with => @with, :user => @user,
                                                    :exemplar_id => @exemplar) }.should
        raise_error(EOL::Exceptions::ClassificationsLocked)
    end

    it 'should not run if providers_match_on_merge' do
      lambda {
        @taxon_concept.should_receive(:providers_match_on_merge).and_return(1)
        @taxon_concept.merge_classifications(@entries, :with => @with, :user => @user,
                                             :exemplar_id => @exemplar) }.should
        raise_error(EOL::Exceptions::ProvidersMatchOnMerge)
    end

    it 'SHOULD run if providers_match_on_merge but forced' do
      ClassificationCuration.should_receive(:create).and_return(nil)
      @taxon_concept.merge_classifications(@entries, :with => @with, :user => @user, :forced => true,
                                           :exemplar_id => @exemplar)
    end

    it 'should not run if merged to self' do
      lambda { @taxon_concept.merge_classifications(@entries, :with => @taxon_concept, :user => @user, :forced => true,
                                                    :exemplar_id => @exemplar) }.should
        raise_error(EOL::Exceptions::CannotMergeClassificationsToSelf)
    end

    it 'should not run if too large' do
      lambda {
        TaxonConceptsFlattened.should_receive(:descendants_of).with(@taxon_concept.id).and_return(@too_many_descendants)
        TaxonConceptsFlattened.should_receive(:descendants_of).with(@with.id).and_return(1)
        @taxon_concept.merge_classifications(@entries, :with => @with, :user => @user, :forced => true,
                                             :exemplar_id => @exemplar)
      }.should
        raise_error(EOL::Exceptions::TooManyDescendantsToCurate)
    end

    it 'should not run if target descendants too large' do
      lambda {
        TaxonConceptsFlattened.should_receive(:descendants_of).with(@with.id).and_return(@too_many_descendants)
        TaxonConceptsFlattened.should_receive(:descendants_of).with(@taxon_concept.id).and_return(1)
        @taxon_concept.merge_classifications(@entries, :with => @with, :user => @user, :forced => true,
                                             :exemplar_id => @exemplar)
      }.should
        raise_error(EOL::Exceptions::TooManyDescendantsToCurate)
    end

    it 'should lock classifications on both concepts and create a ClassificationCuration' do
      TaxonConceptsFlattened.should_receive(:descendants_of).with(@taxon_concept.id).and_return([1])
      TaxonConceptsFlattened.should_receive(:descendants_of).with(@with.id).and_return([1])
      ClassificationCuration.should_receive(:create).and_return(nil)
      @taxon_concept.merge_classifications(@entries, :with => @with, :user => @user, :forced => true,
                                           :exemplar_id => @exemplar)
    end

  end

end
