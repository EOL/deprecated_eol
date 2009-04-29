require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonConcept do

  # we shouldn't need to use scenarios in model specs  :/
  before :all do
    Scenario.load :foundation
  end
  after :all do
    truncate_all_tables
  end

  # Why am I loading so many fixtures in a unit testing suite?  ...Because TaxonConcept is unlike other models: there 
  # is really nothing to it: just an ID and a wee bit of ancillary data. At the same time, TC is *so* vital to
  # everything we do, that I wanted to construct tests that really jog the model through all of its relationships.
  #
  # If you want to think of this as more of a "black-box" test, that's fine.  I chose to put it in the models directory
  # because, well, it isn't testing a website, and it IS testing a *model*, so it seemed a "better" fit here, even if
  # it isn't perfect.
  before(:each) do
    @overview        = TocItem.overview
    @overview_text   = 'This is a test Overview, in all its glory'
    @toc_item_2      = TocItem.gen(:view_order => 2)
    @toc_item_3      = TocItem.gen(:view_order => 3)
    @canonical_form  = Factory.next(:species)
    @attribution     = Faker::Eol.attribution
    @common_name     = Faker::Eol.common_name.firstcap
    @scientific_name = "#{@canonical_form} #{@attribution}"
    @italicized      = "<i>#{@canonical_form}</i> #{@attribution}"
    @iucn_status     = Factory.next(:iucn)
    @map_text        = 'Test Map'
    @image_1         = Factory.next(:image)
    @image_2         = Factory.next(:image)
    @image_3         = Factory.next(:image)
    @video_1_text    = 'First Test Video'
    @video_2_text    = 'Second Test Video'
    @video_3_text    = 'YouTube Test Video'
    @comment_1       = 'This is totally awesome'
    @comment_bad     = 'This is totally inappropriate'
    @comment_2       = 'And I can comment multiple times'
    tc = build_taxon_concept(:rank            => 'species',
                             :canonical_form  => @canonical_form,
                             :attribution     => @attribution,
                             :scientific_name => @scientific_name,
                             :italicized      => @italicized,
                             :common_name     => @common_name,
                             :iucn_status     => @iucn_status,
                             :map             => {:description => @map_text},
                             :flash           => [{:description => @video_1_text}, {:description => @video_2_text}],
                             :youtube         => [{:description => @video_3_text}],
                             :comments        => [{:body => @comment_1},{:body => @comment_bad},{:body => @comment_2}],
                             :images          => [{:object_cache_url => @image_1}, {:object_cache_url => @image_2},
                                                  {:object_cache_url => @image_3}],
                             :toc             => [{:toc_item => @overview, :description => @overview_text}, 
                                                  {:toc_item => @toc_item_2}, {:toc_item => @toc_item_3}])
    @id            = tc.id
    @taxon_concept = TaxonConcept.find(@id)
    # The curator factory cleverly hides a lot of stuff that User.gen can't handle:
    @curator       = Factory(:curator, :curator_hierarchy_entry => tc.entry)
    # Curators aren't recognized until they actually DO something, which is here:
    LastCuratedDate.gen(:user => @curator, :taxon_concept => @taxon_concept)
    # And we want one comment that the world cannot see:
    Comment.find_by_body(@comment_bad).hide!
  end

  it 'should have a canonical form' do
    @taxon_concept.canonical_form.should == @canonical_form
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
    lang = Language.gen(:label => 'Frizzban')
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

  it 'should have an IUCN conservation status' do
    @taxon_concept.iucn_conservation_status.should == @iucn_status
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
    @subspecies1  = build_taxon_concept(:rank => 'subspecies',   :depth => 0, :parent_hierarchy_entry_id => @taxon_concept.entry.id)
    @subspecies2  = build_taxon_concept(:rank => 'subspecies',   :depth => 0, :parent_hierarchy_entry_id => @taxon_concept.entry.id)
    @subspecies3  = build_taxon_concept(:rank => 'subspecies',   :depth => 0, :parent_hierarchy_entry_id => @taxon_concept.entry.id)
    @infraspecies = build_taxon_concept(:rank => 'infraspecies', :depth => 0, :parent_hierarchy_entry_id => @subspecies1.entry.id)
    # Sorted because we don't care about order:
    @taxon_concept.children.map(&:id).sort.should == [@subspecies1.id, @subspecies2.id, @subspecies3.id].sort
  end

  it 'should be able to show a (single) map' do
    # TODO - nice way to add a DO to a TC
    build_data_object('GBIF Image', 'Second map that should not show up',
                      :hierarchy_entry => @taxon_concept.hierarchy_entries.first,
                      :taxon => @taxon_concept.taxa.first,
                      :object_cache_url => Factory.next(:map))
    @taxon_concept.map.should_not be_nil
    @taxon_concept.map.should_not be_an(Array)
    @taxon_concept.map.description.should == @map_text
  end

  it 'should be able to show videos' do
    @taxon_concept.videos.should_not be_nil
    # Sorted because we don't care about order:
    @taxon_concept.videos.map(&:description).sort.should == [@video_1_text, @video_2_text, @video_3_text].sort
  end

  it 'should be able to search' do
    recreate_normalized_names_and_links
    results = TaxonConcept.search(@common_name)
    results[:common].should_not be_nil
    results[:common].map(&:id).should include(@taxon_concept.id)
    results = TaxonConcept.search(@scientific_name.sub(/\s.*$/, '')) # Removes the second half and attribution
    results[:scientific].should_not be_nil
    results[:scientific].map(&:id).should include(@taxon_concept.id)
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

  it 'should be able to show its images' do
    @taxon_concept.images.map(&:object_cache_url).should == [@image_1, @image_2, @image_3]
  end

  it 'should be able to get an overview' do
    results = @taxon_concept.overview
    results.length.should == 1
    results.first.description.should == @overview_text
  end

  # TODO - creating the CP -> Dato relationship is tricky. This should be made available elsewhere:
  it 'should not show content partners THEIR preview items, but not OTHER content partner\'s preview items' do

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
    how_many = @taxon_concept.images.length
    how_many.should > 2
    dato            = @taxon_concept.images.last  # Let's grab the last one...
    # ... And remove it from top images:
    TopImage.delete_all(:hierarchy_entry_id => @taxon_concept.entry.id,
                        :data_object_id => @taxon_concept.images.last.id)
    @taxon_concept.images.length.should == how_many - 1 # Ensuring that we removed it...

    dato.visibility = Visibility.preview
    dato.save!

    DataObjectsHarvestEvent.delete_all(:data_object_id => dato.id)
    dohe           = DataObjectsHarvestEvent.gen(:harvest_event => event, :data_object => dato)

    # Original should see it:
    @taxon_concept.current_agent = original_cp
    @taxon_concept.images.map {|i| i.id }.should include(dato.id)

    # Another CP should not:
    @taxon_concept.current_agent = another_cp
    @taxon_concept.images.map {|i| i.id }.should_not include(dato.id)

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
