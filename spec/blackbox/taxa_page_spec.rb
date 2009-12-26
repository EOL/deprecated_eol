require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

def find_unique_tc(options)
  options[:in].hierarchy_entries.each do |entry|
    return entry.taxon_concept unless entry.taxon_concept.in_hierarchy(options[:not_in])
  end
end

def find_common_tc(options)
  options[:in].hierarchy_entries.each do |entry|
    return entry.taxon_concept if entry.taxon_concept.in_hierarchy(options[:also_in])
  end
end

describe 'Taxa page (HTML)' do

  before(:all) do

    RandomTaxon.delete_all # this should make us green again
    Scenario.load :foundation
    HierarchiesContent.delete_all

    # Long list of items to test:
    begin
      @exemplar        = build_taxon_concept(:id => 910093) # That ID is one of the (hard-coded) exemplars.
    rescue
      #there's already a tc with that id
    end
    @parent          = build_taxon_concept(:images => [], :toc => []) # Somewhat empty, to speed things up.
    @overview        = TocItem.overview
    @overview_text   = 'This is a test Overview, in all its glory'
    # TODO - add a reference to the text object
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
    @user            = User.gen

    @taxon_concept   = build_taxon_concept(
       :parent_hierarchy_entry_id => @parent.hierarchy_entries.first.id,
       :rank            => 'species',
       :canonical_form  => @canonical_form,
       :attribution     => @attribution,
       :scientific_name => @scientific_name,
       :italicized      => @italicized,
       :iucn_status     => @iucn_status,
       :map             => {:description => @map_text},
       :flash           => [{:description => @video_1_text}, {:description => @video_2_text}],
       :youtube         => [{:description => @video_3_text}],
       :comments        => [{:user => @user, :body => @comment_1},{:user => @user, :body => @comment_bad},{:user => @user, :body => @comment_2}],
       # We want more than 10 images, to test pagination, but details don't matter:
       :images          => [{:object_cache_url => @image_1}, {:object_cache_url => @image_2},
                            {:object_cache_url => @image_3}, {}, {}, {}, {}, {}, {}, {}, {}, {}],
       :toc             => [{:toc_item => @overview, :description => @overview_text}, 
                            {:toc_item => @toc_item_2}, {:toc_item => @toc_item_3}])

    # TODO - I am slowly trying to move all of those options over to methods, to make things clearer:
    @taxon_concept.add_common_name(@common_name)
    @child1        = build_taxon_concept(:parent_hierarchy_entry_id => @taxon_concept.hierarchy_entries.first.id)
    @child2        = build_taxon_concept(:parent_hierarchy_entry_id => @taxon_concept.hierarchy_entries.first.id)
    @id            = @taxon_concept.id

    # This is kind of confusing, but basically the next six lines will cause us to ping a host:
    @ping_url      = 'TEST_with_%ID%'
    @ping_id       = '424242'
    @name          = @taxon_concept.taxon_concept_names.first.name
    @collection    = Collection.gen(:ping_host_url => @ping_url)
    @mapping       = Mapping.gen(:collection => @collection, :name => @name, :foreign_key => @ping_id)
    @ping_url.sub!(/%ID%/, @ping_id) # So we can test that it was replaced by the code.
    
    @col_collection = Collection.gen(:agent => Agent.catalogue_of_life, :title => "Catalogue of Life Collection", :uri => "http://www.catalogueoflife.org/browse_taxa.php?selected_taxon=FOREIGNKEY")
    @col_mapping    = Mapping.gen(:collection => @col_collection, :name => @taxon_concept.taxon_concept_names.first.name)
    
    description       = 'user wants <b>bold</b> and <i>italics</i> and <a href="link">links</a>'
    @description_bold = /user wants <(b|strong)>bold<\/(b|strong)>/
    @description_ital = /and <(i|em)>italics<\/(i|em)>/
    @description_link = /and <a href="link">links<\/a>/
    @taxon_concept.add_user_submitted_text(:description => description, :vetted => true)
    @taxon_concept.add_user_submitted_text(:description => description, :vetted => true)

    @toc_item_with_no_trusted_items = TocItem.gen(:label => 'Untrusted Stuff')
    @taxon_concept.add_toc_item(@toc_item_with_no_trusted_items, :vetted => false)

    @curator       = build_curator(@taxon_concept)
    Comment.find_by_body(@comment_bad).hide! User.last
    # doesn't work, why?
    @result        = RackBox.request("/pages/#{@id}") # cache the response the taxon page gives before changes

  end

  after :all do
    truncate_all_tables
  end

  # This is kind of a baseline, did-the-page-actually-load test:
  it 'should include the italicized name in the header' do
    @result = RackBox.request("/pages/#{@id}")
    @result.body.should have_tag('div#page-title') do
      with_tag('h1', :text => @scientific_name)
    end
  end
  
  it 'should use supercedure to find taxon concept' do
    superceded = TaxonConcept.gen(:supercedure_id => @id)
    RackBox.request("/pages/#{superceded.id}").should redirect_to("/pages/#{@id}")
  end
  
  it 'should tell the user the page is missing if the page is... uhhh... missing' do
    missing_id = TaxonConcept.last.id + 1
    while(TaxonConcept.exists?(missing_id)) do
      missing_id += 1
    end
    RackBox.request("/pages/#{missing_id}").body.should have_tag("div#page-title") do
      with_tag('h1', :text => 'Sorry, the page you have requested does not exist.')
    end
  end
  
  it 'should tell the user the page is missing if the TaxonConcept is unpublished' do
    unpublished = TaxonConcept.gen(:published => 0, :supercedure_id => 0)
    RackBox.request("/pages/#{unpublished.id}").body.should have_tag("div#page-title") do
      with_tag('h1', :text => 'Sorry, the page you have requested does not exist.')
    end
  end
  
  it 'should be able to ping the collection host' do
    @result = RackBox.request("/pages/#{@id}")
    @result.body.should include(@ping_url)
  end
  
  it 'should show the Overview text by default' do
    @result = RackBox.request("/pages/#{@id}")
    @result.body.should have_tag('h3', :text => 'Overview')
    @result.body.should include(@overview_text)
  end
  
  it 'should NOT show references for the overview text when there aren\'t any' do
    Ref.delete_all ; @taxon_concept.overview[0].refs = [] # Just to make sure nothing shows up.
    @result = RackBox.request("/pages/#{@id}")
    @result.body.should_not have_tag('div.references')
  end
  
  it 'should show references for the overview text (with URL and DOI identifiers ONLY) when present' do
    full_ref = 'This is the reference text that should show up'
    # TODO - When we add "helper" methods to Rails classes for testing, then "add_reference" could be
    # extracted to do this:
    url_identifier = 'some/url.html'
    doi_identifier = '10.12355/foo/bar.baz.230'
    bad_identifier = 'you should not see this identifier'
    @taxon_concept.overview[0].refs << ref = Ref.gen(:full_reference => full_ref)
    # I heard you like RSpec, so we put a lot of tests in your test so you could spec while you're
    # speccing.There are actually a lot of 'tests' in this test.  For one, we're testing that URLs will have http://
    # added to them if they are blank.  We're also testing the regex that pulls DOIs out of potentially
    # messy DOI identifiers:
    ref.add_identifier('url', url_identifier)
    ref.add_identifier('doi', "doi: #{doi_identifier}")
    ref.add_identifier('bad', bad_identifier)
    new_result = RackBox.request("/pages/#{@id}")
    new_result.body.should have_tag('div.references')
    new_result.body.should include(full_ref)
    new_result.body.should have_tag("a[href=http://#{url_identifier}]")
    new_result.body.should_not include(bad_identifier)
    new_result.body.should have_tag("a[href=http://dx.doi.org/#{doi_identifier}]")
  end
  
  it 'should allow html in user-submitted text' do
    @result = RackBox.request("/pages/#{@id}")
    @result.body.should match(@description_bold)
    @result.body.should match(@description_ital)
    @result.body.should match(@description_link)
  end
  
  # I hate to do this, since it's SO SLOW, but:
  it 'should render an "empty" page in authoritative mode' do
    tc = build_taxon_concept(:common_names => [], :images => [], :toc => [], :flash => [], :youtube => [],
                             :comments => [], :bhl => [])
    this_result = RackBox.request("/pages/#{tc.id}?vetted=true")
    this_result.body.should_not include('Internal Server Error')
    this_result.body.should have_tag('h1') # Whatever, let's just prove that it renders.
  end
  
  it 'should show the Catalogue of Life link in Specialist Projects' do
    this_result = RackBox.request("/pages/#{@taxon_concept.id}?category_id=#{TocItem.specialist_projects.id}")
    this_result.body.should include(@col_collection.title)
  end
  
  it 'should show the Catalogue of Life link in the header' do
    body = RackBox.request("/pages/#{@taxon_concept.id}").body
    body.should include("recognized by <a href=\"#{@col_mapping.url}\"")
  end
  
  describe 'specified hierarchies' do
    
    before(:all) do
      truncate_all_tables
      Scenario.load :bootstrap # I *know* we shouldn't load bootstrap for testing, so if (when?) this breaks, that
                               # sceneraio's salient bits will need extracting.
      @ncbi = Hierarchy.find_by_label('NCBI Taxonomy')
      @user_with_default_hierarchy = User.gen(:password => 'whatever', :default_hierarchy_id => Hierarchy.default.id)
      @user_with_ncbi_hierarchy    = User.gen(:password => 'whatever', :default_hierarchy_id => @ncbi.id)
      @user_with_nil_hierarchy     = User.gen(:password => 'whatever', :default_hierarchy_id => nil)
      @user_with_missing_hierarchy = User.gen(:password => 'whatever', :default_hierarchy_id => 100056) # Seems safe not to assert this
      @default_tc = find_unique_tc(:in => Hierarchy.default, :not_in => @ncbi)
      @ncbi_tc    = find_unique_tc(:not_in => Hierarchy.default, :in => @ncbi)
      @common_tc  = find_common_tc(:in => Hierarchy.default, :also_in => @ncbi)
    end
    
    it "should see 'not in hierarchy' message when the user doesn't specify a default hierarchy and page is not in default hierarchy" do
      login_as @user_with_nil_hierarchy
      res = request("/pages/#{@ncbi_tc.id}")
      res.should include_text("Name not in #{Hierarchy.default.label.gsub("&", "&amp;")}")
    end
    
    it "should see 'not in hierarchy' message when the user has NCBI hierarchy and page is not in NCBI" do
      login_as @user_with_ncbi_hierarchy
      request("/pages/#{@default_tc.id}").should include_text("Name not in #{@ncbi.label}")
    end
    
    it "should attribute the default hierarchy when the user doesn't specify one and the page is in both hierarchies" do
      login_as @user_with_nil_hierarchy
      request("/pages/#{@common_tc.id}").should include_text("recognized by <a href=\"#{Hierarchy.default.agent.homepage.strip}")
    end
    
    it "should attribute the default hierarchy when the user has it as the default and page is in both hierarchies" do
      login_as @user_with_default_hierarchy
      request("/pages/#{@common_tc.id}").should include_text("recognized by <a href=\"#{Hierarchy.default.agent.homepage.strip}")
    end
    
    it "should use the label from the NCBI hierarchy when the user has it as the default and page is in both hierarchies" do
      login_as @user_with_ncbi_hierarchy
      request("/pages/#{@common_tc.id}").should include_text("recognized by #{@ncbi.label}")
    end
  end
  
  # Red background/icon on untrusted videos
  it "should show red background for untrusted video links"
  it "should not show red background for trusted video links"
  it "should show red box with 'Videos in red are not trusted.' if there are untrusted videos"
  it "should not show red box with 'Videos in red are not trusted.' if there are no untrusted videos"
  it "should show red background around player for untrusted videos"
  it "should not show red background around player for trusted videos"
  it "should show red information button if untrusted video plays"
  it "should show green information button if trusted video plays"
  it "should show red background for notes area if untrusted video plays"
  it "should not show red background for notes area if trusted video plays"
  
  # LigerCat Medical Concepts Tag Cloud
  it 'should link to LigerCat when the Medical Concepts content is displayed'
    # TODO - this will simply: 1) ensure the TC has a biomedical_terms toc item, 2) load that page with the
    # content_id for biomedical_terms, and 3) verify that the page includes the URL we expect.
    
  # permalinks for species comments
  it 'should load comment with the id when comment_id is specified'
  it 'should hide image when load comment'
  it 'should have only comments tab active (blue dot)'
  it 'should not show comment when another tab chosen'
  
  #image permalinks
  it 'should load image as main image when image_id is specified'
  it 'should switch current_user.vetted to false when image_id is specified and is a unknown or untrusted image'
  it 'should paginate to the correct page when image_id is specified and does not exist on the first page of thumbnails'
  it 'should return 404 page when permalink image_id is specified that doesn\'t exist in the database'
  it 'should return 404 page when permalink image_id is specified that isn\'t associated with species page'
  it 'should return 404 page when permalink image_id is specified for an image which is hidden and user which isn\'t a curator'
  it 'should load hidden image via permalink when user is a curator of the page'
  it 'should return 404 page when permalink image_id is specified for an image which has been removed'
  it 'should load removed image via permalink when user is an admin'
  
  #text permalinks
  it 'should switch selected TOC when text_id is specified and not on the default selected TOC'
  it 'should current_user.vetted to false when permalink with text_id is specified for a text object which is unknown or untrusted'
  it 'should return 404 page when loading permalink for text which doesn\'t exist in the database'
  it 'should return 404 page when loading permalink for text which isn\'t associated with species page'
  it 'should return 404 page when loading permalink for text which is hidden when the user isn\'t a curator'
  it 'should load hidden text via permalink when user is a curator of the page'
  it 'should return 404 page when loading permalink for text which has been removed and user isn\'t an admin'
  it 'should load removed text via permalink when user is an admin'
  
  it 'should include the TocItem with only unvetted content in it' do
    @result = RackBox.request("/pages/#{@id}")
    @result.body.should have_tag('a', :text => /#{@toc_item_with_no_trusted_items.label}/)
  end
  
  it 'should show info item label for the overview text when there isn\'t an object_title' do
    info_item_title = InfoItem.find(:last)
    data_object = @taxon_concept.overview.first
    DataObjectsInfoItem.gen(:data_object => data_object, :info_item => InfoItem.find(:last))
    
    data_object.object_title = ""
    data_object.save!
    new_result = RackBox.request("/pages/#{@id}")
    new_result.body.should include(info_item_title.label)
    
    # show object_title if it exists
    data_object.object_title = "Some Title"
    data_object.save!
    new_result = RackBox.request("/pages/#{@id}")
    new_result.body.should include(data_object.object_title)
    new_result.body.should_not include(info_item_title.label)        
  end

end

