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
    Scenario.load :foundation
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
      tc.add_common_name_synonym(@common_name, @curator.agent, :language => Language.english)
    # Curators aren't recognized until they actually DO something, which is here:
    LastCuratedDate.gen(:user => @curator, :taxon_concept => @taxon_concept)
    # And we want one comment that the world cannot see:
    Comment.find_by_body(@comment_bad).hide! User.last
    @user = User.gen
  end
  after :all do
    truncate_all_tables
  end

  it 'should capitalize the title (even if the name starts with a quote)' do
    good_title = %Q{"Good title"}
    bad_title = good_title.downcase
    tc = build_taxon_concept(:canonical_form => bad_title)
    tc.title.should =~ /#{good_title}/
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

  it 'should set the common name to the correct language' do
    lang = Language.gen(:label => 'Ancient Egyptian')
    user = User.gen(:language => lang)
    str  = 'Frebblebup'
    name = Name.gen(:string => str)
    TaxonConceptName.gen(:language => lang, :name => name, :taxon_concept => @taxon_concept)
    @taxon_concept.current_user = user
    @taxon_concept.common_name.should == str
  end

  it 'should let you get/set the current user' do
    user = User.gen
    @taxon_concept.current_user = user
    @taxon_concept.current_user.should == user
  end

  it 'should have a default IUCN conservation status of NOT EVALUATED' do
    @taxon_concept.iucn_conservation_status.should == 'NOT EVALUATED'
  end

  it 'should have an IUCN conservation status' do
    tc = build_taxon_concept()
    iucn_status = Factory.next(:iucn)
    build_iucn_entry(tc, iucn_status)
    tc.iucn_conservation_status.should == iucn_status
  end

  it 'should have an IUCN conservation status even if it comes from another IUCN resource' do
    tc = build_taxon_concept()
    iucn_status = Factory.next(:iucn)
    (hierarchy, resource) = build_secondary_iucn_hierarchy_and_resource
    build_iucn_entry(tc, iucn_status, :hierarchy => hierarchy,
                                                  :event => HarvestEvent.gen(:resource => resource))
    tc.iucn_conservation_status.should == iucn_status
  end

  it 'should have only one IUCN conservation status when there could have been many (doesnt matter which)' do
    build_iucn_entry(@taxon_concept, Factory.next(:iucn))
    build_iucn_entry(@taxon_concept, Factory.next(:iucn))
    result = @taxon_concept.iucn
    result.should be_an_instance_of DataObject # (not an Array, mind you.)
  end

  it 'should not use an unpublished IUCN status' do
    tc = build_taxon_concept()
    bad_iucn = build_iucn_entry(tc, 'bad value')
    tc.iucn_conservation_status.should == 'bad value'
    
    # We *must* know that it would have worked if it *were* published, otherwise the test proves nothing:
    tc2 = build_taxon_concept()
    bad_iucn2 = build_iucn_entry(tc2, 'bad value')
    bad_iucn2.published = 0
    bad_iucn2.save
    tc2.iucn_conservation_status.should == 'NOT EVALUATED'
  end

  it 'should be able to list its ancestors (by convention, ending with itself)' do
    @kingdom = build_taxon_concept(:rank => 'kingdom', :depth => 0)
    @phylum  = build_taxon_concept(:rank => 'phylum',  :depth => 1, :parent_hierarchy_entry_id => @kingdom.entry.id)
    @order   = build_taxon_concept(:rank => 'order',   :depth => 2, :parent_hierarchy_entry_id => @phylum.entry.id)
    # Now we attach our TC to those:
    he = @taxon_concept.entry
    he.parent_id = @order.entry.id
    he.save
    @taxon_concept.ancestors.map(&:id).should == [@kingdom.id, @phylum.id, @order.id, @taxon_concept.id]
  end

  it 'should be able to list its children (NOT descendants, JUST children--animalia would be a disaster!)' do
    @subspecies1  = build_taxon_concept(:rank => 'subspecies', :depth => 4,
                                        :parent_hierarchy_entry_id => @taxon_concept.entry.id)
    @subspecies2  = build_taxon_concept(:rank => 'subspecies', :depth => 4,
                                        :parent_hierarchy_entry_id => @taxon_concept.entry.id)
    @subspecies3  = build_taxon_concept(:rank => 'subspecies', :depth => 4,
                                        :parent_hierarchy_entry_id => @taxon_concept.entry.id)
    @infraspecies = build_taxon_concept(:rank => 'infraspecies', :depth => 4,
                                        :parent_hierarchy_entry_id => @subspecies1.entry.id)
    @taxon_concept.children.map(&:id).should only_include @subspecies1.id, @subspecies2.id, @subspecies3.id
  end

  it 'should find its GBIF map ID' do
    @taxon_concept.gbif_map_id.should == @gbif_map_id
  end

  it 'should be able to show videos' do
    @taxon_concept.videos.should_not be_nil
    @taxon_concept.videos.map(&:description).should only_include @video_1_text, @video_2_text, @video_3_text
  end

  it 'should have visible comments that don\'t show invisible comments' do
    user = User.gen
    @taxon_concept.visible_comments.should_not be_nil
    @taxon_concept.visible_comments.map(&:body).should == [@comment_1, @comment_2] # Order DOES matter, now.
  end

  it 'should be able to show a table of contents' do
    # Tricky, tricky. See, we add special things to the TOC like "Common Names" and "Search the Web", when they are appropriate.  I
    # could test for those here, but that seems the perview of TocItem.  So, I'm only checking the first three elements:
    @taxon_concept.toc[0..2].should == [@overview, @toc_item_2, @toc_item_3]
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

  it 'should show its untrusted images, by default' do
    @taxon_concept.current_user = User.create_new # It's okay if this one "sticks", so no cleanup code
    @taxon_concept.images.map(&:object_cache_url).should include(@image_unknown_trust)
  end

  it 'should show only trusted images if the user prefers' do
    old_user = @taxon_concept.current_user
    @taxon_concept.current_user = User.gen(:vetted => true)
    @taxon_concept.images.map(&:object_cache_url).should only_include(@image_1, @image_2, @image_3)
    @taxon_concept.current_user = old_user  # Cleaning up so as not to affect other tests
  end

  it 'should be able to get an overview' do
    results = @taxon_concept.overview
    results.length.should == 1
    results.first.description.should == @overview_text
  end
  
  # TODO - creating the CP -> Dato relationship is tricky. This should be made available elsewhere:
  it 'should show content partners THEIR preview items, but not OTHER content partner\'s preview items' do

    original_cp    = Agent.gen
    another_cp     = Agent.gen
    resource       = Resource.gen
    # Note this doesn't work without the ResourceAgentRole setting.  :\
    agent_resource = AgentsResource.gen(:agent_id => original_cp.id, :resource_id => resource.id,
                       :resource_agent_role_id => ResourceAgentRole.content_partner_upload_role.id)
    event          = HarvestEvent.gen(:resource => resource)
    # Note this *totally* doesn't work if you don't add it to top_unpublished_images!
    TopUnpublishedImage.gen(:hierarchy_entry => @taxon_concept.entry,
                            :data_object     => @taxon_concept.images.last)
    TopUnpublishedConceptImage.gen(:taxon_concept => @taxon_concept,
                            :data_object     => @taxon_concept.images.last)
    how_many = @taxon_concept.images.length
    how_many.should > 2
    dato            = @taxon_concept.images.last  # Let's grab the last one...
    # ... And remove it from top images:
    TopImage.delete_all(:hierarchy_entry_id => @taxon_concept.entry.id,
                        :data_object_id => @taxon_concept.images.last.id)
    TopConceptImage.delete_all(:taxon_concept_id => @taxon_concept.id,
                        :data_object_id => @taxon_concept.images.last.id)
    
    Rails.cache.delete("data_object/cached_images_for/#{@taxon_concept.id}")  # deleting the concept image cache
    @taxon_concept.current_user = @taxon_concept.current_user #hack to expire cached images
    @taxon_concept.images.length.should == how_many - 1 # Ensuring that we removed it...

    dato.visibility = Visibility.preview
    dato.save!

    DataObjectsHarvestEvent.delete_all(:data_object_id => dato.id)
    dohe           = DataObjectsHarvestEvent.gen(:harvest_event => event, :data_object => dato)
    
    # puts 'okok'
    # pp @taxon_concept.top_concept_images
    # pp @taxon_concept.top_unpublished_concept_images
    # pp @taxon_concept.entry.top_unpublished_images
    # Original should see it:
    @taxon_concept.current_agent = original_cp
    # pp @taxon_concept.images
    @taxon_concept.images.map {|i| i.id }.should include(dato.id)

    # Another CP should not:
    @taxon_concept.current_agent = another_cp
    @taxon_concept.images.map {|i| i.id }.should_not include(dato.id)

  end
  
  it "should have common names" do
    TaxonConcept.common_names_for?(@taxon_concept.id).should == true
  end

  it "should not have common names" do
    tc = build_taxon_concept(:toc=> [
      {:toc_item => TocItem.common_names}
    ])  
    TaxonConcept.common_names_for?(tc.id).should == false
  end

  it 'should return images sorted by trusted, unknown, untrusted' do
    @taxon_concept.current_user = @user
    trusted   = Vetted.trusted.id
    unknown   = Vetted.unknown.id
    untrusted = Vetted.untrusted.id
    @taxon_concept.images.map {|i| i.vetted_id }.should == [trusted, trusted, trusted, unknown, untrusted]
  end

  it 'should sort the vetted images by data rating' do
    @taxon_concept.current_user = @user
    @taxon_concept.images[0..2].map(&:object_cache_url).should == [@image_3, @image_2, @image_1]
  end

  it 'should create a common name as a preferred common name, if there are no other common names for the taxon' do
    tc = build_taxon_concept(:common_names => [])
    agent = Agent.last # TODO - I don't like this.  We shouldn't need it for tests.  Overload the method for testing?
    tc.add_common_name_synonym('A name', agent, :language => Language.english)
    tc.quick_common_name.should == "A name"
    tc.add_common_name_synonym("Another name", agent, :language => Language.english)
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
    tc = build_taxon_concept(:images => [], :toc => [], :flash => [], :youtube => [], :comments => [], :bhl => [])
    tc.tocitem_for_new_text.class.should == TocItem
  end

  it 'should return description as first toc item which accepts user submitted text' do
    description_toc = TocItem.find_by_label('Description')
    InfoItem.gen(:toc_id => @overview.id)
    InfoItem.gen(:toc_id => description_toc.id)
    tc = build_taxon_concept(:images => [], :flash => [], :youtube => [], :comments => [], :bhl => [],
                             :toc => [{:toc_item => description_toc, :description => 'huh?'}])
    tc.tocitem_for_new_text.label.should == description_toc.label
  end

  it 'should include the LigerCat TocItem when the TaxonConcept has one'

  it 'should NOT include the LigerCat TocItem when the TaxonConcept does NOT have one'

  it 'should have a canonical form' do
    @taxon_concept.canonical_form.should == @canonical_form
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

  describe "#add_common_name" do
    before(:all) do
      @tcn_count = TaxonConceptName.count
      @syn_count = Synonym.count
      @name_count = Name.count
      @name_string = "Piping plover"
      @agent = Agent.find(@curator.agent_id)
      @language = Language.english
      @synonym = @taxon_concept.add_common_name_synonym(@name_string, @agent, :language => @language)
      @name = @synonym.name
      @tcn = @synonym.taxon_concept_name
    end

    it "should increase name count, taxon name count, synonym count" do
      TaxonConceptName.count.should == @tcn_count + 1
      Synonym.count.should == @syn_count + 1
      Name.count.should == @name_count + 1
    end

    it "should mark first created name for a language as preferred automatically" do
      language = Language.gen(:label => "Russian") 
      s= @taxon_concept.add_common_name_synonym("Саблезубая сосиска", @agent, :language => language)
      TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(@taxon_concept, language).size.should == 1
      TaxonConceptName.find_by_synonym_id(s.id).preferred?.should be_true
      s = @taxon_concept.add_common_name_synonym("Голый землекоп", @agent, :language => language)
      TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(@taxon_concept, language).size.should == 2
      TaxonConceptName.find_by_synonym_id(s.id).preferred?.should be_false
    end

    it "should not mark first created name as preffered for unknown language" do
      language = Language.unknown
      s = @taxon_concept.add_common_name_synonym("Саблезубая сосиска", @agent, :language => language)
      TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(@taxon_concept, language).size.should == 1
      TaxonConceptName.find_by_synonym_id(s.id).preferred?.should be_false
    end

    it "should create new name object" do
      @name.class.should == Name
      @name.string.should == @name_string
    end

    it "should create synonym" do
      @synonym.class.should == Synonym
      @synonym.name.should == @name
      @synonym.agents.should == [@curator.agent]
    end

    it "should create taxon_concept_name" do
      @tc_name.class.should == TaxonConceptName
      @tc_name.synonym.should == @synonym
    end

    it "should be able to create a common name with the same name string but different language" do
      @taxon_concept.add_common_name_synonym(@name_string, Agent.find(@curator.agent_id), :language => Language.find_by_label("French"))
      TaxonConceptName.count.should == @tcn_count + 2
      Synonym.count.should == @syn_count + 2
      Name.count.should == @name_count + 1
    end
  end


  describe "#delete_common_name" do
    before(:all) do
      @synonym = @taxon_concept.add_common_name_synonym("Piping plover", Agent.find(@curator.agent_id), :language => Language.english)
      @tc_name = @synonym.taxon_concept_name
      @tcn_count = TaxonConceptName.count
      @syn_count = Synonym.count
      @name_count = Name.count
    end

    it "should delete a common name" do
      @taxon_concept.delete_common_name(@tc_name)
      TaxonConceptName.count.should == @tcn_count - 1
      Synonym.count.should == @syn_count - 1
      Name.count.should == @name_count #name is not deleted
    end

    it "should delete preffered common names, should mark last common name for a language as preferred" do
      pref_en_name = TaxonConceptName.find_by_taxon_concept_id_and_language_id_and_preferred(@taxon_concept, Language.english, true)
      all_en_names = TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(@taxon_concept, Language.english)
      all_en_names.size.should == 2
      @tc_name.preferred?.should be_false
      @taxon_concept.delete_common_name(pref_en_name) #it should work now because it is the only name left
      TaxonConceptName.count.should == @tcn_count - 1
      Synonym.count.should == @syn_count - 1
      Name.count.should == @name_count
      TaxonConceptName.find_by_synonym_id(@tc_name.synonym.id).preferred?.should be_true
      @taxon_concept.delete_common_name(@tc_name)
      TaxonConceptName.count.should == @tcn_count - 2
      Synonym.count.should == @syn_count - 2
      Name.count.should == @name_count
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
