require File.dirname(__FILE__) + '/../spec_helper'

def build_secondary_iucn_hierarchy_and_resource
  Agent.iucn.user ||= User.gen(:agent => Agent.iucn)
  Agent.iucn.user.content_partner ||= ContentPartner.gen(:user => Agent.iucn.user)
  another_iucn_resource  = Resource.gen(:title  => 'Another IUCN', :content_partner => Agent.iucn.user.content_partner)
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
    @taxon_concept.video_data_objects.should_not be_nil
    @taxon_concept.video_data_objects.map(&:description).should only_include @video_1_text, @video_2_text, @video_3_text
  end

  it 'should have visible comments that don\'t show invisible comments' do
    user = User.gen
    @taxon_concept.visible_comments.should_not be_nil
    @taxon_concept.visible_comments.map(&:body).should == [@comment_1, @comment_2] # Order DOES matter, now.
  end

  it 'should be able to show a table of contents' do
    # Tricky, tricky. See, we add special things to the TOC like "Common Names" and "Search the Web", when they are appropriate.  I
    # could test for those here, but that seems the perview of TocItem.  So, I'm only checking the first three elements:
    @taxon_concept.toc[0..3].should == [@overview, @testy[:brief_summary], @toc_item_2, @toc_item_3]
  end

  # TODO - this is failing, but low-priority, I added a bug for it: EOLINFRASTRUCTURE-657
  # This was related to a bug (EOLINFRASTRUCTURE-598)
  #it 'should return the table of contents with unpublished items when a content partner is specified' do
    #cp   = ContentPartner.gen
    #toci = TocItem.gen
    #dato = build_data_object('Text', 'This is our target text',
                             #:hierarchy_entry => @taxon_concept.hierarchy_entries.first, :content_partner => cp,
                             #:published => false, :vetted => Vetted.unknown, :toc_item => toci)
    #@taxon_concept.toc.map(&:id).should_not include(toci.id)
    #@taxon_concept.current_agent = cp.agent
    #@taxon_concept.toc.map(&:id).should include(toci.id)
  #end

  it 'should have images and videos in #media' do
    @taxon_concept.media.map(&:description).should include(@video_1_text)
    @taxon_concept.media.map(&:object_cache_url).should include(@testy[:image_1])
  end

  it 'should show its untrusted images, by default' do
    @taxon_concept.current_user = User.create_new # It's okay if this one "sticks", so no cleanup code
    @taxon_concept.images.map(&:object_cache_url).should include(@image_unknown_trust)
  end

  it 'should show only trusted images if the user prefers' do
    old_user = @taxon_concept.current_user
    @taxon_concept.current_user = User.gen(:vetted => true)
    @taxon_concept.images.map(&:vetted_id).uniq.should only_include(Vetted.trusted.id)
    @taxon_concept.current_user = old_user  # Cleaning up so as not to affect other tests
  end

  it 'should be able to get an overview' do
    results = @taxon_concept.overview
    results.length.should == 1
    results.first.description.should == @overview_text
  end

  # TODO - creating the CP -> Dato relationship is tricky. This should be made available elsewhere:
  it 'should show content partners THEIR preview items, but not OTHER content partner\'s preview items' do
    @taxon_concept.reload
    @taxon_concept.current_user = nil
    primary_user = User.gen
    ContentPartner.gen(:user => primary_user)
    different_user = User.gen
    ContentPartner.gen(:user => different_user)

    cp_hierarchy   = Hierarchy.gen(:agent => primary_user.agent)
    resource       = Resource.gen(:hierarchy => cp_hierarchy, :content_partner => primary_user.content_partner)
    event          = HarvestEvent.gen(:resource => resource)
    # Note this *totally* doesn't work if you don't add it to top_unpublished_images!
    TopUnpublishedImage.gen(:hierarchy_entry => @taxon_concept.entry,
                            :data_object     => @taxon_concept.images.last)
    TopUnpublishedConceptImage.gen(:taxon_concept => @taxon_concept,
                            :data_object     => @taxon_concept.images.last)
    how_many = @taxon_concept.images.length
    how_many.should > 2
    dato = @taxon_concept.images.last  # Let's grab the last one...
    # ... And remove it from top images:
    TopImage.delete_all(:hierarchy_entry_id => @taxon_concept.entry.id,
                        :data_object_id => @taxon_concept.images.last.id)
    TopConceptImage.delete_all(:taxon_concept_id => @taxon_concept.id,
                        :data_object_id => @taxon_concept.images.last.id)

    @taxon_concept.reload
    @taxon_concept.images.length.should == how_many - 1 # Ensuring that we removed it...

    # object must be in preview mode for the Content Partner to have exclusive access
    dato.visibility = Visibility.preview
    dato.save!

    DataObjectsHarvestEvent.delete_all(:data_object_id => dato.id)
    DataObjectsHierarchyEntry.delete_all(:data_object_id => dato.id)
    he = HierarchyEntry.gen(:hierarchy => cp_hierarchy, :taxon_concept => @taxon_concept)
    DataObjectsHierarchyEntry.gen(:hierarchy_entry => he, :data_object => dato)
    DataObjectsHarvestEvent.gen(:harvest_event => event, :data_object => dato)
    HierarchyEntry.connection.execute("COMMIT")

    # Original should see it:
    @taxon_concept.reload
    @taxon_concept.current_user = primary_user
    @taxon_concept.images(:user => primary_user).map {|i| i.id }.should include(dato.id)

    # Another CP should not:
    tc = TaxonConcept.find(@taxon_concept.id) # hack to reload the object and delete instance variables
    tc.current_user = different_user
    tc.images.map {|i| i.id }.should_not include(dato.id)
  end

  it "should have common names" do
    @taxon_concept.has_common_names?.should == true
  end

  it "should not have common names" do
    @tc_with_no_common_names.has_common_names?.should == false
  end

  it 'should return images sorted by trusted, unknown, untrusted but preview mode first' do
    @taxon_concept.reload
    trusted   = Vetted.trusted.id
    unknown   = Vetted.unknown.id
    untrusted = Vetted.untrusted.id
    @taxon_concept.images.map {|i| i.vetted_id }.uniq.should == [untrusted, trusted, unknown]
  end

  it 'should sort the vetted images by data rating' do
    @taxon_concept.current_user = @user
    ratings = @taxon_concept.images.select {|i| i.vetted_id == Vetted.trusted.id }.map(&:data_rating)
    ratings.should == ratings.sort.reverse
  end

  it 'should create a common name as a preferred common name, if there are no other common names for the taxon' do
    tc = @tc_with_no_common_names # TODO - this depends on the order of tests.
    agent = Agent.last # TODO - I don't like this.  We shouldn't need it for tests.  Overload the method for testing?
    tc.add_common_name_synonym('A name', :agent => agent, :language => Language.english)
    tc.quick_common_name.should == "A name"
    tc.add_common_name_synonym("Another name", :agent => agent, :language => Language.english)
    tc.quick_common_name.should == "A name"
  end

  it 'should determine and cache curation authorization' do
    @curator.can_curate?(@taxon_concept).should == true
    @curator.should_receive('can_curate?').and_return(true)
    @taxon_concept.show_curator_controls?(@curator).should == true
    @curator.should_not_receive('can_curate?')
    @taxon_concept.show_curator_controls?(@curator).should == true
  end

  it 'should return a toc item which accepts user submitted text' do
    @taxon_concept.tocitem_for_new_text.class.should == TocItem
    @empty_taxon_concept.tocitem_for_new_text.class.should == TocItem
  end

  it 'should return first toc item which accepts user submitted text' do
    @taxon_concept.tocitem_for_new_text.label.should == @overview.label
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

  # TODO - this is failing, but low-priority, I added a bug for it: EOLINFRASTRUCTURE-657
  # This was related to a bug (EOLINFRASTRUCTURE-598)
  #it 'should return the table of contents with unpublished items when a content partner is specified' do
    #cp   = ContentPartner.gen
    #toci = TocItem.gen
    #dato = build_data_object('Text', 'This is our target text',
                             #:hierarchy_entry => @taxon_concept.hierarchy_entries.first, :content_partner => cp,
                             #:published => false, :vetted => Vetted.unknown, :toc_item => toci)
    #@taxon_concept.toc.map(&:id).should_not include(toci.id)
    #@taxon_concept.current_agent = cp.agent
    #@taxon_concept.toc.map(&:id).should include(toci.id)
  #end

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
    TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(@taxon_concept, Language.english).each do |tcn|
      tcn.delete
    end

    # first one should go in as preferred
    first_syn = @taxon_concept.add_common_name_synonym('First english name', :agent => @agent, :language => Language.english)
    first_tcn = TaxonConceptName.find_by_synonym_id(first_syn.id)
    first_tcn.preferred?.should be_true

    # second should not be preferred
    second_syn = @taxon_concept.add_common_name_synonym('Second english name', :agent => @agent, :language => Language.english)
    second_tcn = TaxonConceptName.find_by_synonym_id(second_syn.id)
    second_tcn.preferred?.should be_false

    # after removing the first, the last one should change to preferred
    @taxon_concept.delete_common_name(first_tcn)
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

  it 'should have a feed' do
    tc = TaxonConcept.gen
    tc.respond_to?(:feed).should be_true
    tc.feed.should be_a EOL::Feed
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
