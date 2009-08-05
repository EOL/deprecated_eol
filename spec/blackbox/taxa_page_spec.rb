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
       :common_names    => [@common_name],
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
    
    description       = 'user wants <b>bold</b> and <i>italics</i> and <a href="link">links</a>'
    @description_bold = /user wants <(b|strong)>bold<\/(b|strong)>/
    @description_ital = /and <(i|em)>italics<\/(i|em)>/
    @description_link = /and <a href="link">links<\/a>/
    @taxon_concept.add_user_submitted_text(:description => description, :vetted => true)

    @curator       = build_curator(@taxon_concept)
    Comment.find_by_body(@comment_bad).hide! User.last
    @result        = RackBox.request("/pages/#{@id}") # cache the response the taxon page gives before changes

  end

  after :all do
    truncate_all_tables
  end

  # This is kind of a baseline, did-the-page-actually-load test:
  it 'should include the italicized name in the header' do
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
    @result.body.should include(@ping_url)
  end

  it 'should show the Overview text by default' do
    @result.body.should have_tag('h3', :text => 'Overview')
    @result.body.should include(@overview_text)
  end

  it 'should NOT show references for the overview text when there aren\'t any' do
    Ref.delete_all ; @taxon_concept.overview[0].refs = [] # Just to make sure nothing shows up.
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
      request("/pages/#{@ncbi_tc.id}").should include_text("Name not in #{Hierarchy.default.label}")
    end
    
    it "should see 'not in hierarchy' message when the user has NCBI hierarchy and page is not in NCBI" do
      login_as @user_with_ncbi_hierarchy
      request("/pages/#{@default_tc.id}").should include_text("Name not in #{@ncbi.label}")
    end
    
    it "should use the label from the default hierarchy when the user doesn't specify one and the page is in both hierarchies" do
      login_as @user_with_nil_hierarchy
      request("/pages/#{@common_tc.id}").should include_text("recognized by #{CGI.escapeHTML(Hierarchy.default.label)}")
    end
    
    it "should use the label from the default hierarchy when the user has it as the default and page is in both hierarchies" do
      login_as @user_with_default_hierarchy
      request("/pages/#{@common_tc.id}").should include_text("recognized by #{CGI.escapeHTML(Hierarchy.default.label)}")
    end
    
    it "should use the label from the NCBI hierarchy when the user has it as the default and page is in both hierarchies" do
      login_as @user_with_ncbi_hierarchy
      request("/pages/#{@common_tc.id}").should include_text("recognized by #{@ncbi.label}")
    end

    it 'should load image as main image when image_id is specified'

    it 'should switch current_user.vetted to false when image_id is specified and is a unknown or untrusted image'

    it 'should paginate to the correct page when image_id is specified and does not exist on the first page of thumbnails'
  end


end

