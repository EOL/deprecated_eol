require File.dirname(__FILE__) + '/../spec_helper'

def build_secondary_iucn_hierarchy_and_resource
  another_iucn_resource  = Resource.gen(:title  => 'Another IUCN')
  another_iucn_hierarchy = Hierarchy.gen(:label => 'Another IUCN')
  AgentsResource.gen(:agent => Agent.iucn, :resource => another_iucn_resource)
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
    load_foundation_cache
    @overview        = TocItem.overview
    @overview_text   = 'This is a test Overview, in all its glory'
    @toc_item_2      = TocItem.gen(:view_order => 2)
    @toc_item_3      = TocItem.gen(:view_order => 3)
    @canonical_form  = Factory.next(:species)
    @attribution     = Faker::Eol.attribution
    @common_name     = Faker::Eol.common_name.firstcap
    @scientific_name = "#{@canonical_form} #{@attribution}"
    @italicized      = "<i>#{@canonical_form}</i> #{@attribution}"
    @gbif_map_id     = '424242'
    @image_1         = Factory.next(:image)
    @image_2         = Factory.next(:image)
    @image_3         = Factory.next(:image)
    @image_unknown_trust = Factory.next(:image)
    @image_untrusted = Factory.next(:image)
    @video_1_text    = 'First Test Video'
    @video_2_text    = 'Second Test Video'
    @video_3_text    = 'YouTube Test Video'
    @comment_1       = 'This is totally awesome'
    @comment_bad     = 'This is totally inappropriate'
    @comment_2       = 'And I can comment multiple times'
    tc = build_taxon_concept(
      :rank            => 'species',
      :canonical_form  => @canonical_form,
      :attribution     => @attribution,
      :scientific_name => @scientific_name,
      :italicized      => @italicized,
      :gbif_map_id     => @gbif_map_id,
      :flash           => [{:description => @video_1_text}, {:description => @video_2_text}],
      :youtube         => [{:description => @video_3_text}],
      :comments        => [{:body => @comment_1}, {:body => @comment_bad}, {:body => @comment_2}],
      :images          => [{:object_cache_url => @image_1, :data_rating => 2},
                           {:object_cache_url => @image_2, :data_rating => 3},
                           {:object_cache_url => @image_untrusted, :vetted => Vetted.untrusted},
                           {:object_cache_url => @image_3, :data_rating => 4},
                           {:object_cache_url => @image_unknown_trust, :vetted => Vetted.unknown}],
      :toc             => [{:toc_item => @overview, :description => @overview_text}, 
                           {:toc_item => @toc_item_2}, {:toc_item => @toc_item_3}]
    )
    @id            = tc.id
    @taxon_concept = TaxonConcept.find(@id)
    # The curator factory cleverly hides a lot of stuff that User.gen can't handle:
    @curator       = build_curator(@taxon_concept)
    # TODO - I am slowly trying to convert all of the above options to methods to make testing clearer:
    (@common_name_obj, @synonym_for_common_name, @tcn_for_common_name) =
      tc.add_common_name_synonym(@common_name, :agent => @curator.agent, :language => Language.english)
    # Curators aren't recognized until they actually DO something, which is here:
    LastCuratedDate.gen(:user => @curator, :taxon_concept => @taxon_concept)
    # And we want one comment that the world cannot see:
    Comment.find_by_body(@comment_bad).hide User.last
    @user = User.gen
  end
  after :all do
    truncate_all_tables
  end

#T  it 'should capitalize the title (even if the name starts with a quote)' do
#T    good_title = %Q{"Good title"}
#T    bad_title = good_title.downcase
#T    tc = build_taxon_concept(:canonical_form => bad_title)
#T    tc.title.should =~ /#{good_title}/
#T  end
#T  
#T  it 'should have curators' do
#T    @taxon_concept.curators.map(&:id).should include(@curator.id)
#T  end
#T  
#T  it 'should have a scientific name (italicized for species)' do
#T    @taxon_concept.scientific_name.should == @italicized
#T  end
#T  
#T  it 'should have a common name' do
#T    @taxon_concept.common_name.should == @common_name
#T  end
#T  
#T  it 'should show the common name from the current users language' do
#T    lang = Language.gen(:label => 'Ancient Egyptian')
#T    user = User.gen(:language => lang)
#T    str  = 'Frebblebup'
#T    @taxon_concept.add_common_name_synonym(str, :agent => user.agent, :language => lang)
#T    @taxon_concept.current_user = user
#T    @taxon_concept.common_name.should == str
#T  end
#T  
#T  it 'should let you get/set the current user' do
#T    user = User.gen
#T    @taxon_concept.current_user = user
#T    @taxon_concept.current_user.should == user
#T  end
#T  
#T  it 'should have a default IUCN conservation status of NOT EVALUATED' do
#T    @taxon_concept.iucn_conservation_status.should == 'NOT EVALUATED'
#T  end
#T  
#T  it 'should have an IUCN conservation status' do
#T    tc = build_taxon_concept()
#T    iucn_status = Factory.next(:iucn)
#T    build_iucn_entry(tc, iucn_status)
#T    tc.iucn_conservation_status.should == iucn_status
#T  end
#T  
#T  it 'should NOT have an IUCN conservation status even if it comes from another IUCN resource' do
#T    tc = build_taxon_concept()
#T    iucn_status = Factory.next(:iucn)
#T    (hierarchy, resource) = build_secondary_iucn_hierarchy_and_resource
#T    build_iucn_entry(tc, iucn_status, :hierarchy => hierarchy,
#T                                                  :event => HarvestEvent.gen(:resource => resource))
#T    tc.iucn_conservation_status.should == 'NOT EVALUATED'
#T  end
#T  
#T  it 'should have only one IUCN conservation status when there could have been many (doesnt matter which)' do
#T    build_iucn_entry(@taxon_concept, Factory.next(:iucn))
#T    build_iucn_entry(@taxon_concept, Factory.next(:iucn))
#T    result = @taxon_concept.iucn
#T    result.should be_an_instance_of DataObject # (not an Array, mind you.)
#T  end
#T  
#T  it 'should not use an unpublished IUCN status' do
#T    tc = build_taxon_concept()
#T    bad_iucn = build_iucn_entry(tc, 'bad value')
#T    tc.iucn_conservation_status.should == 'bad value'
#T    
#T    # We *must* know that it would have worked if it *were* published, otherwise the test proves nothing:
#T    tc2 = build_taxon_concept()
#T    bad_iucn2 = build_iucn_entry(tc2, 'bad value')
#T    bad_iucn2.published = 0
#T    bad_iucn2.save
#T    tc2.iucn_conservation_status.should == 'NOT EVALUATED'
#T  end
#T  
#T  it 'should be able to list its ancestors (by convention, ending with itself)' do
#T    @kingdom = build_taxon_concept(:rank => 'kingdom', :depth => 0)
#T    @phylum  = build_taxon_concept(:rank => 'phylum',  :depth => 1, :parent_hierarchy_entry_id => @kingdom.entry.id)
#T    @order   = build_taxon_concept(:rank => 'order',   :depth => 2, :parent_hierarchy_entry_id => @phylum.entry.id)
#T    # Now we attach our TC to those:
#T    he = @taxon_concept.entry
#T    he.parent_id = @order.entry.id
#T    he.save
#T    @taxon_concept.ancestors.map(&:id).should == [@kingdom.id, @phylum.id, @order.id, @taxon_concept.id]
#T  end
#T  
#T  it 'should be able to list its children (NOT descendants, JUST children--animalia would be a disaster!)' do
#T    @subspecies1  = build_taxon_concept(:rank => 'subspecies', :depth => 4,
#T                                        :parent_hierarchy_entry_id => @taxon_concept.entry.id)
#T    @subspecies2  = build_taxon_concept(:rank => 'subspecies', :depth => 4,
#T                                        :parent_hierarchy_entry_id => @taxon_concept.entry.id)
#T    @subspecies3  = build_taxon_concept(:rank => 'subspecies', :depth => 4,
#T                                        :parent_hierarchy_entry_id => @taxon_concept.entry.id)
#T    @infraspecies = build_taxon_concept(:rank => 'infraspecies', :depth => 4,
#T                                        :parent_hierarchy_entry_id => @subspecies1.entry.id)
#T    @taxon_concept.children.map(&:id).should only_include @subspecies1.id, @subspecies2.id, @subspecies3.id
#T  end
#T  
#T  it 'should find its GBIF map ID' do
#T    @taxon_concept.gbif_map_id.should == @gbif_map_id
#T  end
#T  
#T  it 'should be able to show videos' do
#T    @taxon_concept.videos.should_not be_nil
#T    @taxon_concept.videos.map(&:description).should only_include @video_1_text, @video_2_text, @video_3_text
#T  end
#T  
#T  it 'should have visible comments that don\'t show invisible comments' do
#T    user = User.gen
#T    @taxon_concept.visible_comments.should_not be_nil
#T    @taxon_concept.visible_comments.map(&:body).should == [@comment_1, @comment_2] # Order DOES matter, now.
#T  end
#T  
#T  it 'should be able to show a table of contents' do
#T    # Tricky, tricky. See, we add special things to the TOC like "Common Names" and "Search the Web", when they are appropriate.  I
#T    # could test for those here, but that seems the perview of TocItem.  So, I'm only checking the first three elements:
#T    @taxon_concept.toc[0..2].should == [@overview, @toc_item_2, @toc_item_3]
#T  end
#T  
#T  # TODO - this is failing, but low-priority, I added a bug for it: EOLINFRASTRUCTURE-657
#T  # This was related to a bug (EOLINFRASTRUCTURE-598)
#T  #it 'should return the table of contents with unpublished items when a content partner is specified' do
#T    #cp   = ContentPartner.gen
#T    #toci = TocItem.gen
#T    #dato = build_data_object('Text', 'This is our target text',
#T                             #:hierarchy_entry => @taxon_concept.hierarchy_entries.first, :content_partner => cp,
#T                             #:published => false, :vetted => Vetted.unknown, :toc_item => toci)
#T    #@taxon_concept.toc.map(&:id).should_not include(toci.id)
#T    #@taxon_concept.current_agent = cp.agent
#T    #@taxon_concept.toc.map(&:id).should include(toci.id)
#T  #end
#T  
#T  it 'should show its untrusted images, by default' do
#T    @taxon_concept.current_user = User.create_new # It's okay if this one "sticks", so no cleanup code
#T    @taxon_concept.images.map(&:object_cache_url).should include(@image_unknown_trust)
#T  end
#T  
#T  it 'should show only trusted images if the user prefers' do
#T    old_user = @taxon_concept.current_user
#T    @taxon_concept.current_user = User.gen(:vetted => true)
#T    @taxon_concept.images.map(&:object_cache_url).should only_include(@image_1, @image_2, @image_3)
#T    @taxon_concept.current_user = old_user  # Cleaning up so as not to affect other tests
#T  end
#T  
#T  it 'should be able to get an overview' do
#T    results = @taxon_concept.overview
#T    results.length.should == 1
#T    results.first.description.should == @overview_text
#T  end
#T  
#T  # TODO - creating the CP -> Dato relationship is tricky. This should be made available elsewhere:
#T  it 'should show content partners THEIR preview items, but not OTHER content partner\'s preview items' do
#T  
#T    original_cp    = Agent.gen
#T    another_cp     = Agent.gen
#T    resource       = Resource.gen
#T    # Note this doesn't work without the ResourceAgentRole setting.  :\
#T    agent_resource = AgentsResource.gen(:agent_id => original_cp.id, :resource_id => resource.id,
#T                       :resource_agent_role_id => ResourceAgentRole.content_partner_upload_role.id)
#T    event          = HarvestEvent.gen(:resource => resource)
#T    # Note this *totally* doesn't work if you don't add it to top_unpublished_images!
#T    TopUnpublishedImage.gen(:hierarchy_entry => @taxon_concept.entry,
#T                            :data_object     => @taxon_concept.images.last)
#T    TopUnpublishedConceptImage.gen(:taxon_concept => @taxon_concept,
#T                            :data_object     => @taxon_concept.images.last)
#T    how_many = @taxon_concept.images.length
#T    how_many.should > 2
#T    dato            = @taxon_concept.images.last  # Let's grab the last one...
#T    # ... And remove it from top images:
#T    TopImage.delete_all(:hierarchy_entry_id => @taxon_concept.entry.id,
#T                        :data_object_id => @taxon_concept.images.last.id)
#T    TopConceptImage.delete_all(:taxon_concept_id => @taxon_concept.id,
#T                        :data_object_id => @taxon_concept.images.last.id)
#T    
#T    $CACHE.delete("data_object/cached_images_for/#{@taxon_concept.id}")  # deleting the concept image cache
#T    @taxon_concept.current_user = @taxon_concept.current_user #hack to expire cached images
#T    @taxon_concept.images.length.should == how_many - 1 # Ensuring that we removed it...
#T  
#T    dato.visibility = Visibility.preview
#T    dato.save!
#T  
#T    DataObjectsHarvestEvent.delete_all(:data_object_id => dato.id)
#T    dohe           = DataObjectsHarvestEvent.gen(:harvest_event => event, :data_object => dato)
#T    
#T    # puts 'okok'
#T    # pp @taxon_concept.top_concept_images
#T    # pp @taxon_concept.top_unpublished_concept_images
#T    # pp @taxon_concept.entry.top_unpublished_images
#T    # Original should see it:
#T    @taxon_concept.current_agent = original_cp
#T    # pp @taxon_concept.images
#T    @taxon_concept.images.map {|i| i.id }.should include(dato.id)
#T  
#T    # Another CP should not:
#T    tc = TaxonConcept.find(@taxon_concept.id) # hack to reload the object and delete instance variables
#T    tc.current_agent = another_cp
#T    tc.images.map {|i| i.id }.should_not include(dato.id)
#T  
#T  end
#T  
#T  it "should have common names" do
#T    TaxonConcept.common_names_for?(@taxon_concept.id).should == true
#T  end
#T  
#T  it "should not have common names" do
#T    tc = build_taxon_concept(:toc=> [
#T      {:toc_item => TocItem.common_names}
#T    ])  
#T    TaxonConcept.common_names_for?(tc.id).should == false
#T  end
#T  
#T  it 'should return images sorted by trusted, unknown, untrusted' do
#T    @taxon_concept.current_user = @user
#T    trusted   = Vetted.trusted.id
#T    unknown   = Vetted.unknown.id
#T    untrusted = Vetted.untrusted.id
#T    @taxon_concept.images.map {|i| i.vetted_id }.should == [trusted, trusted, trusted, unknown, untrusted]
#T  end
#T  
#T  it 'should sort the vetted images by data rating' do
#T    @taxon_concept.current_user = @user
#T    @taxon_concept.images[0..2].map(&:object_cache_url).should == [@image_3, @image_2, @image_1]
#T  end
#T  
#T  it 'should create a common name as a preferred common name, if there are no other common names for the taxon' do
#T    tc = build_taxon_concept(:common_names => [])
#T    agent = Agent.last # TODO - I don't like this.  We shouldn't need it for tests.  Overload the method for testing?
#T    tc.add_common_name_synonym('A name', :agent => agent, :language => Language.english)
#T    tc.quick_common_name.should == "A name"
#T    tc.add_common_name_synonym("Another name", :agent => agent, :language => Language.english)
#T    tc.quick_common_name.should == "A name"
#T  end
#T  
#T  it 'should determine and cache curation authorization' do
#T    @curator.can_curate?(@taxon_concept).should == true
#T    @curator.should_receive('can_curate?').and_return(true)
#T    @taxon_concept.show_curator_controls?(@curator).should == true
#T    @curator.should_not_receive('can_curate?')
#T    @taxon_concept.show_curator_controls?(@curator).should == true
#T  end
#T  
#T  it 'should return a toc item which accepts user submitted text' do
#T    @taxon_concept.tocitem_for_new_text.class.should == TocItem
#T    tc = build_taxon_concept(:images => [], :toc => [], :flash => [], :youtube => [], :comments => [], :bhl => [])
#T    tc.tocitem_for_new_text.class.should == TocItem
#T  end
#T  
#T  it 'should return description as first toc item which accepts user submitted text' do
#T    description_toc = TocItem.find_by_label('Description')
#T    InfoItem.gen(:toc_id => @overview.id)
#T    InfoItem.gen(:toc_id => description_toc.id)
#T    tc = build_taxon_concept(:images => [], :flash => [], :youtube => [], :comments => [], :bhl => [],
#T                             :toc => [{:toc_item => description_toc, :description => 'huh?'}])
#T    tc.tocitem_for_new_text.label.should == description_toc.label
#T  end
#T  
#T  it 'should include the LigerCat TocItem when the TaxonConcept has one'
#T  
#T  it 'should NOT include the LigerCat TocItem when the TaxonConcept does NOT have one'
#T  
#T  it 'should have a canonical form' do
#T    @taxon_concept.canonical_form.should == @canonical_form
#T  end
#T  
#T  it 'should cite a vetted source for the page when there are both vetted and unvetted sources' do
#T    h_vetted = Hierarchy.gen()
#T    h_unvetted = Hierarchy.gen()
#T    concept = TaxonConcept.gen(:published => 1, :vetted => Vetted.trusted)
#T    concept.entry.should be_nil
#T    
#T    # adding an unvetted name and testing
#T    unvetted_name = Name.gen(:canonical_form => cf = CanonicalForm.gen(:string => 'Annnvettedname'),
#T                      :string => 'Annnvettedname',
#T                      :italicized => '<i>Annnvettedname</i>')
#T    he_unvetted = build_hierarchy_entry(0, concept, unvetted_name,
#T                                :hierarchy => h_unvetted,
#T                                :vetted_id => Vetted.unknown.id,
#T                                :published => 1)
#T    concept = TaxonConcept.find(concept.id) # cheating so I can flush all the instance variables
#T    concept.entry.should_not be_nil
#T    concept.entry.id.should == he_unvetted.id
#T    concept.name.should == unvetted_name.italicized
#T    
#T    # adding a vetted name and testing
#T    vetted_name = Name.gen(:canonical_form => cf = CanonicalForm.gen(:string => 'Avettedname'),
#T                      :string => 'Avettedname',
#T                      :italicized => '<i>Avettedname</i>')
#T    he_vetted = build_hierarchy_entry(0, concept, vetted_name,
#T                                :hierarchy => h_vetted,
#T                                :vetted_id => Vetted.trusted.id,
#T                                :published => 1)
#T    concept = TaxonConcept.find(concept.id) # cheating so I can flush all the instance variables
#T    concept.entry.id.should == he_vetted.id
#T    concept.name.should == vetted_name.italicized
#T    
#T    # adding another unvetted name to test the vetted name remains
#T    another_unvetted_name = Name.gen(:canonical_form => cf = CanonicalForm.gen(:string => 'Anotherunvettedname'),
#T                      :string => 'Anotherunvettedname',
#T                      :italicized => '<i>Anotherunvettedname</i>')
#T    he_anotherunvetted = build_hierarchy_entry(0, concept, another_unvetted_name,
#T                                :hierarchy => h_vetted,
#T                                :vetted_id => Vetted.unknown.id,
#T                                :published => 1)
#T    concept = TaxonConcept.find(concept.id) # cheating so I can flush all the instance variables
#T    concept.entry.id.should == he_vetted.id
#T    concept.name.should == vetted_name.italicized
#T    
#T    # now remove the vetted hierarchy entry and make sure the first entry is the chosen one
#T    he_vetted.destroy
#T    concept = TaxonConcept.find(concept.id) # cheating so I can flush all the instance variables
#T    concept.entry.id.should == he_unvetted.id
#T    concept.name.should == unvetted_name.italicized
#T  end
#T  
#T  # TODO - this is failing, but low-priority, I added a bug for it: EOLINFRASTRUCTURE-657
#T  # This was related to a bug (EOLINFRASTRUCTURE-598)
#T  #it 'should return the table of contents with unpublished items when a content partner is specified' do
#T    #cp   = ContentPartner.gen
#T    #toci = TocItem.gen
#T    #dato = build_data_object('Text', 'This is our target text',
#T                             #:hierarchy_entry => @taxon_concept.hierarchy_entries.first, :content_partner => cp,
#T                             #:published => false, :vetted => Vetted.unknown, :toc_item => toci)
#T    #@taxon_concept.toc.map(&:id).should_not include(toci.id)
#T    #@taxon_concept.current_agent = cp.agent
#T    #@taxon_concept.toc.map(&:id).should include(toci.id)
#T  #end
#T  
#T  describe "#add_common_name" do
#T    before(:all) do
#T      @tcn_count = TaxonConceptName.count
#T      @syn_count = Synonym.count
#T      @name_count = Name.count
#T      @name_string = "Piping plover"
#T      @agent = Agent.find(@curator.agent_id)
#T      @synonym = @taxon_concept.add_common_name_synonym(@name_string, :agent => @agent, :language => Language.english)
#T      @name = @synonym.name
#T      @tcn = @synonym.taxon_concept_name
#T    end
#T  
#T    it "should increase name count, taxon name count, synonym count" do
#T      TaxonConceptName.count.should == @tcn_count + 1
#T      Synonym.count.should == @syn_count + 1
#T      Name.count.should == @name_count + 1
#T    end
#T  
#T    it "should mark first created name for a language as preferred automatically" do
#T      language = Language.gen(:label => "Russian") 
#T      weird_name = "Саблезубая сосиска"
#T      s = @taxon_concept.add_common_name_synonym(weird_name, :agent => @agent, :language => language)
#T      TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(@taxon_concept, language).size.should == 1
#T      TaxonConceptName.find_by_synonym_id(s.id).preferred?.should be_true
#T      weird_name = "Голый землекоп"
#T      s = @taxon_concept.add_common_name_synonym(weird_name, :agent => @agent, :language => language)
#T      TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(@taxon_concept, language).size.should == 2
#T      TaxonConceptName.find_by_synonym_id(s.id).preferred?.should be_false
#T    end
#T  
#T    it "should not mark first created name as preffered for unknown language" do
#T      language = Language.unknown
#T      weird_name = "Саблезубая сосиска"
#T      s = @taxon_concept.add_common_name_synonym(weird_name, :agent => @agent, :language => language)
#T      TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(@taxon_concept, language).size.should == 1
#T      TaxonConceptName.find_by_synonym_id(s.id).preferred?.should be_false
#T    end
#T  
#T    it "should create new name object" do
#T      @name.class.should == Name
#T      @name.string.should == @name_string
#T    end
#T  
#T    it "should create synonym" do
#T      @synonym.class.should == Synonym
#T      @synonym.name.should == @name
#T      @synonym.agents.should == [@curator.agent]
#T    end
#T  
#T    it "should create taxon_concept_name" do
#T      @tcn.should_not be_nil
#T    end
#T  
#T    it "should be able to create a common name with the same name string but different language" do
#T      @taxon_concept.add_common_name_synonym(@name_string, :agent => Agent.find(@curator.agent_id), :language => Language.find_by_label("French"))
#T      TaxonConceptName.count.should == @tcn_count + 2
#T      Synonym.count.should == @syn_count + 2
#T      Name.count.should == @name_count + 1
#T    end
#T  end
#T  
#T  
#T  describe "#delete_common_name" do
#T    before(:all) do
#T      @synonym = @taxon_concept.add_common_name_synonym("Piping plover", :agent => Agent.find(@curator.agent_id), :language => Language.english)
#T      @tc_name = @synonym.taxon_concept_name
#T      @tcn_count = TaxonConceptName.count
#T      @syn_count = Synonym.count
#T      @name_count = Name.count
#T    end
#T  
#T    it "should delete a common name" do
#T      @taxon_concept.delete_common_name(@tc_name)
#T      TaxonConceptName.count.should == @tcn_count - 1
#T      Synonym.count.should == @syn_count - 1
#T      Name.count.should == @name_count #name is not deleted
#T    end
#T  
#T    it "should delete preffered common names, should mark last common name for a language as preferred" do
#T      pref_en_name = TaxonConceptName.find_by_taxon_concept_id_and_language_id_and_preferred(@taxon_concept, Language.english, true)
#T      all_en_names = TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(@taxon_concept, Language.english)
#T      all_en_names.size.should == 2
#T      @tc_name.preferred?.should be_false
#T      @taxon_concept.delete_common_name(pref_en_name) #it should work now because it is the only name left
#T      TaxonConceptName.count.should == @tcn_count - 1
#T      Synonym.count.should == @syn_count - 1
#T      Name.count.should == @name_count
#T      TaxonConceptName.find_by_synonym_id(@tc_name.synonym.id).preferred?.should be_true
#T      @taxon_concept.delete_common_name(@tc_name)
#T      TaxonConceptName.count.should == @tcn_count - 2
#T      Synonym.count.should == @syn_count - 2
#T      Name.count.should == @name_count
#T    end
#T  
#T  end
  
  describe 'vetting common names' do

    before(:each) do
      @another_curator = build_curator(@taxon_concept)
      @taxon_concept.current_user = @another_curator
      @name ||= "Some name"
      @language = Language.english
      @syn1 = @taxon_concept.add_common_name_synonym(@name, :agent => @curator.agent, :language => @language)
      @tcn1 = TaxonConceptName.find_by_synonym_id(@syn1.id)
      @name_obj ||= Name.last
      @he2  ||= build_hierarchy_entry(1, @taxon_concept, @name_obj)
      # Slightly different method, in order to attach it to a different HE:
      @syn2 = Synonym.generate_from_name(@name_obj, :entry => @he2, :language => @language, :agent => @curator.agent)
      @tcn2 = TaxonConceptName.find_by_synonym_id(@syn2.id)
    end

    it 'should untrust all synonyms and TCNs related to a TC when untrusted' do
      # Make them all "trusted" first:
      [@syn1, @syn2, @tcn1, @tcn2].each {|obj| obj.update_attributes!(:vetted => Vetted.trusted) }
      @taxon_concept.vet_common_name(:vetted => Vetted.untrusted, :language_id => @language.id, :name_id => @name_obj.id)
      @syn1.reload.vetted_id.should == Vetted.untrusted.id
      @syn2.reload.vetted_id.should == Vetted.untrusted.id
      @tcn1.reload.vetted_id.should == Vetted.untrusted.id
      @tcn2.reload.vetted_id.should == Vetted.untrusted.id
    end

    it 'should "unreview" all synonyms and TCNs related to a TC when unreviewed' do
      # Make them all "trusted" first:
      [@syn1, @syn2, @tcn1, @tcn2].each {|obj| obj.update_attributes!(:vetted => Vetted.trusted) }
      @taxon_concept.vet_common_name(:vetted => Vetted.unknown, :language_id => @language.id, :name_id => @name_obj.id)
      @syn1.reload.vetted_id.should == Vetted.unknown.id
      @syn2.reload.vetted_id.should == Vetted.unknown.id
      @tcn1.reload.vetted_id.should == Vetted.unknown.id
      @tcn2.reload.vetted_id.should == Vetted.unknown.id
    end

    it 'should trust all synonyms and TCNs related to a TC when trusted' do
      # Make them all "unknown" first:
      [@syn1, @syn2, @tcn1, @tcn2].each {|obj| obj.update_attributes!(:vetted => Vetted.unknown) }
      @taxon_concept.vet_common_name(:vetted => Vetted.trusted, :language_id => @language.id, :name_id => @name_obj.id)
      @syn1.reload.vetted_id.should == Vetted.trusted.id
      @syn2.reload.vetted_id.should == Vetted.trusted.id
      @tcn1.reload.vetted_id.should == Vetted.trusted.id
      @tcn2.reload.vetted_id.should == Vetted.trusted.id
    end

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
