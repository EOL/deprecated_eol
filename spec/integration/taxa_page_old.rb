require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

# TODO: Make sure the relevant tests from here have been moved to the appropriate V2 spec then delete this file.

class TaxonConcept
  def self.missing_id
    missing_id = TaxonConcept.last.id + 1
    while(TaxonConcept.exists?(missing_id)) do
      missing_id += 1
    end
    missing_id
  end
end

def find_unique_tc(options)
  options[:in].hierarchy_entries.each do |entry|
    return entry.taxon_concept unless entry.taxon_concept.in_hierarchy?(options[:not_in])
  end
end

def find_common_tc(options)
  options[:in].hierarchy_entries.each do |entry|
    return entry.taxon_concept if entry.taxon_concept.in_hierarchy?(options[:also_in])
  end
end

describe 'Taxa page (HTML)' do

  before(:all) do

    truncate_all_tables
    load_scenario_with_caching(:testy)
    testy = EOL::TestInfo.load('testy')
    Capybara.reset_sessions!

    @exemplar        = testy[:exemplar]
    @overview        = testy[:overview]
    @cnames_toc      = TocItem.common_names.id
    @overview_text   = testy[:overview_text]
    @common_name     = testy[:common_name]
    @scientific_name = testy[:scientific_name]
    @italicized      = testy[:italicized]
    @iucn_status     = testy[:iucn_status]
    @map_text        = testy[:map_text]
    @comment_bad     = testy[:comment_bad]
    @taxon_concept   = testy[:taxon_concept]
    @child1          = testy[:child1]
    @child2          = testy[:child2]
    @id              = testy[:id]
    @feed_body_1     = testy[:feed_body_1]
    @feed_body_2     = testy[:feed_body_2]
    @feed_body_3     = testy[:feed_body_3]
    @nameless        = testy[:taxon_concept_with_no_common_names]
    @empty           = testy[:empty_taxon_concept]

    # This is kind of confusing, but basically the next six lines will cause us to ping a host:
    @ping_url      = 'TEST_with_%ID%'
    @ping_id       = '424242'
    @name          = @taxon_concept.taxon_concept_names.first.name
    @collection    = Hierarchy.gen(:ping_host_url => @ping_url)
    @mapping       = HierarchyEntry.gen(:hierarchy => @collection, :name => @name, :identifier => @ping_id, :taxon_concept => @taxon_concept)
    @ping_url.sub!(/%ID%/, @ping_id) # So we can test that it was replaced by the code.

    @col_collection = Hierarchy.gen(:agent => Agent.catalogue_of_life, :label => "Catalogue of Life Collection", :outlink_uri => "http://www.catalogueoflife.org/browse_taxa.php?selected_taxon=%%ID%%")
    @col_mapping    = @taxon_concept.entry_for_agent(Agent.catalogue_of_life.id) || HierarchyEntry.gen(:hierarchy => @col_collection, :name => @taxon_concept.taxon_concept_names.first.name, :taxon_concept => @taxon_concept)
    @col_mapping.source_url = "http://example.com"
    @col_mapping.save

    description       = 'user wants <b>bold</b> and <i>italics</i> and <a href="link">links</a>'
    @description_bold = /user wants <(b|strong)>bold<\/(b|strong)>/
    @description_ital = /and <(i|em)>italics<\/(i|em)>/
    @description_link = /and <a href="link">links<\/a>/
    @taxon_concept.add_user_submitted_text(:description => description, :vetted => true)
    @taxon_concept.add_user_submitted_text(:description => description, :vetted => true)

    @toc_item_with_no_trusted_items = TocItem.gen_if_not_exists(:label => 'Untrusted Stuff')
    @taxon_concept.add_toc_item(@toc_item_with_no_trusted_items, :vetted => false)

    @curator       = build_curator(@taxon_concept)
    Comment.find_by_body(@comment_bad).hide User.last

    make_all_nested_sets
    flatten_hierarchies

    @taxon_concept.reload
    visit("/pages/#{@id}") # cache the response the taxon page gives before changes
    @result = page
  end

  # after :all do
  #   truncate_all_tables
  # end

  # This is kind of a baseline, did-the-page-actually-load test:
  it 'should include the italicized name in the header' do
    @result.body.should have_tag('div#page-title') do
      with_tag('h1', :text => @scientific_name)
    end
  end

  it 'should show the common name if one exists' do
    @result.body.should have_tag('div#page-title') do
      with_tag('h2', :text => @common_name)
    end
  end

  it 'should NOT show a view/edit link after the common name when non-curator' do
    @result.body.should have_tag('div#page-title') do
      with_tag('h2') do
        without_tag("span#curate-common-names")
        without_tag("span", :text => /view\/edit/)
      end
    end
  end

  it 'should not show the common name if none exists' do
    visit("/pages/#{@nameless.id}")
    body.should have_tag('div#page-title') do
      with_tag('h2', :text => '')
    end
  end

  it 'should use supercedure to find taxon concept' do
    superceded = TaxonConcept.gen(:supercedure_id => @id)
    visit("/pages/#{superceded.id}")
    current_path.should == "/pages/#{@id}"
  end

  it 'should show comments from superceded taxa' do
    taxon1 = TaxonConcept.gen(:published => 1, :supercedure_id => 0)
    taxon2 = TaxonConcept.gen(:supercedure_id => taxon1.id)
    comment = Comment.gen(:parent_type => "TaxonConcept", :parent_id => taxon2.id, :body => "my comment...")
    visit("comments/?tab=1&taxon_concept_id=#{taxon1.id}")
    body.should include("my comment...")
  end

  it 'should tell the user the page is missing if the page is... uhhh... missing' do
    visit("/pages/#{TaxonConcept.missing_id}")
  end

  it 'should tell the user the page is missing if the TaxonConcept is unpublished' do
    unpublished = TaxonConcept.gen(:published => 0, :supercedure_id => 0)
    visit("/pages/#{unpublished.id}")
    body.should have_tag("div#page-title") do
      with_tag('h1', :text => 'Sorry, the page you have requested does not exist.')
    end
  end

  it 'should render when an object has no agents' do
    taxon_concept = build_taxon_concept # Drat.  ...But we need to delete things from it, so it would be wrong to keep it.
    first_image = taxon_concept.top_concept_images[0].data_object
    first_agent_name = first_image.agents[0].full_name

    visit("/pages/#{taxon_concept.id}")
    body.should have_tag("img.main-image")
    body.should include(first_agent_name)  # verify the agent exists

    first_image.agents.each{|a| a.delete}
    visit("/pages/#{taxon_concept.id}")
    body.should have_tag("img.main-image")
    body.should_not include(first_agent_name) # verify the agent is gone yet the page still loads
  end

  it 'should show the Overview text by default' do
    visit("/pages/#{@id}")
    body.should have_tag('div.cpc-header') do
      with_tag('h3', :text => 'Overview')
    end
    body.should include(@overview_text)
  end

  it 'should NOT show references for the overview text when there aren\'t any' do
    Ref.delete_all
    visit("/pages/#{@id}")
    body.should_not have_tag('div.references')
  end

  it 'should show references for the overview text (with URL and DOI identifiers ONLY) when present' do
    full_ref = 'This is the reference text that should show up'
    # TODO - When we add "helper" methods to Rails classes for testing, then "add_reference" could be
    # extracted to do this:
    url_identifier = 'some/url.html'
    doi_identifier = '10.12355/foo/bar.baz.230'
    bad_identifier = 'you should not see this identifier'
    @taxon_concept.overview[0].refs << ref = Ref.gen(:full_reference => full_ref, :published => 1, :visibility => Visibility.visible)
    # I heard you like RSpec, so we put a lot of tests in your test so you could spec while you're
    # speccing.There are actually a lot of 'tests' in this test.  For one, we're testing that URLs will have http://
    # added to them if they are blank.  We're also testing the regex that pulls DOIs out of potentially
    # messy DOI identifiers:
    ref.add_identifier('url', url_identifier)
    ref.add_identifier('doi', "doi: #{doi_identifier}")
    ref.add_identifier('bad', bad_identifier)
    visit("/pages/#{@id}")
    body.should have_tag('div.references')
    body.should include(full_ref)
    body.should have_tag("a[href=http://#{url_identifier}]")
    body.should_not include(bad_identifier)
    body.should have_tag("a[href=http://dx.doi.org/#{doi_identifier}]")
  end

  it 'should NOT show references for the overview text when reference is invisible' do
    full_ref = 'This is the reference text that should show up'
    @taxon_concept.overview[0].refs << ref = Ref.gen(:full_reference => full_ref, :published => 1, :visibility => Visibility.invisible)
    visit("/pages/#{@id}")
    body.should_not have_tag('div.references')
  end

  it 'should NOT show references for the overview text when reference is unpublished' do
    full_ref = 'This is the reference text that should show up'
    @taxon_concept.overview[0].refs << ref = Ref.gen(:full_reference => full_ref, :published => 0, :visibility => Visibility.visible)
    visit("/pages/#{@id}")
    body.should_not have_tag('div.references')
  end

  it 'should allow html in user-submitted text' do
    visit("/pages/#{@id}")
    body.should match(@description_bold)
    body.should match(@description_ital)
    body.should match(@description_link)
  end

  # is this empty as in no data or empty as in a missing taxon?
  it 'should render an "empty" page in authoritative mode' do
    visit("/pages/#{@empty.id}?vetted=true")
    body.should_not include('Internal Server Error')
    body.should have_tag('h1') # Whatever, let's just prove that it renders.
  end

  it 'should show common names with their trust levels in the Common Names toc item' do
    visit("/pages/#{@taxon_concept.id}?category_id=#{@cnames_toc}")
    body.should have_tag("div#common_names_wrapper") do
      with_tag('td.trusted',    :text => @common_name)
      with_tag('td.unreviewed', :text => @unreviewed_name)
      with_tag('td.untrusted',  :text => @untrusted_name)
    end
  end

  it 'should show the Catalogue of Life link in Content Partners' do
    visit("/pages/#{@taxon_concept.id}?category_id=#{TocItem.content_partners.id}")
    body.should include(@col_mapping.hierarchy.label)
  end

  it 'should show the Catalogue of Life link in the header' do
    visit("/pages/#{@taxon_concept.id}")
    body.should include("recognized by <a href=\"#{@col_mapping.source_url}\"")
  end

  it 'should show a Nucleotide Sequences table of content item if concept in NCBI and has identifier' do
    # make an entry in NCBI for this concept and give it an identifier
    sci_name = Name.gen(:string => Factory.next(:scientific_name) + 'tps') # A little more to make sure it's unique.
    entry = build_hierarchy_entry(0, @taxon_concept, sci_name,
                :identifier => 1234,
                :hierarchy => Hierarchy.ncbi )

    visit("/pages/#{@taxon_concept.id}")
    body.should include("Nucleotide Sequences")
  end

  it 'should show not a Nucleotide Sequences table of content item if concept in NCBI and does not have an identifier' do
    # make an entry in NCBI for this concept and dont give it an identifier
    sci_name = Name.gen
    entry = build_hierarchy_entry(0, @taxon_concept, sci_name,
                :hierarchy => Hierarchy.ncbi )

    visit("/pages/#{@taxon_concept.id}")
    body.should_not include("Nucleotide Sequences")
  end

  it 'should show the hierarchy descriptive label in the drop down if there is one' do
    col = Hierarchy.default
    @result.body.should match /value='#{col.id}'>\s*#{col.label}\s*<\/option>/ # selector default

    col.descriptive_label = 'A DIFFERENT LABEL FOR TESTING'
    col.save!
    visit("/pages/#{@id}")
    body.should match /value='#{col.id}'>\s*#{col.descriptive_label}\s*<\/option>/ # selector default

    col.descriptive_label = nil
    col.save!
  end

  describe 'specified hierarchies' do

    before(:all) do
      #creating an NCBI hierarchy and some others
      Hierarchy.delete_all("label = 'NCBI Taxonomy'") # Not sure why, but we end up with lots of these.
      @ncbi = Hierarchy.gen(:agent => Agent.ncbi, :label => "NCBI Taxonomy", :browsable => 1)
      @browsable_hierarchy = Hierarchy.gen(:label => "Browsable Hierarchy", :browsable => 1)
      @non_browsable_hierarchy = Hierarchy.gen(:label => "NonBrowsable Hierarchy", :browsable => 0)

      # making entries for this concept in the new hierarchies
      HierarchyEntry.gen(:hierarchy => @ncbi, :taxon_concept => @taxon_concept, :rank => Rank.species)
      HierarchyEntry.gen(:hierarchy => @browsable_hierarchy, :taxon_concept => @taxon_concept, :rank => Rank.species)
      HierarchyEntry.gen(:hierarchy => @non_browsable_hierarchy, :taxon_concept => @taxon_concept, :rank => Rank.species)

      # and another entry just in NCBI
      HierarchyEntry.gen(:hierarchy => @ncbi, :rank => Rank.species)
      @user_with_default_hierarchy = User.gen(:default_hierarchy_id => Hierarchy.default.id)
      @user_with_ncbi_hierarchy    = User.gen(:default_hierarchy_id => @ncbi.id)
      @user_with_nil_hierarchy     = User.gen(:default_hierarchy_id => nil)
      @user_with_missing_hierarchy = User.gen(:default_hierarchy_id => 100056) # Seems safe not to assert this
      @default_tc = find_unique_tc(:in => Hierarchy.default, :not_in => @ncbi)
      @ncbi_tc    = find_unique_tc(:not_in => Hierarchy.default, :in => @ncbi)
      @common_tc  = find_common_tc(:in => Hierarchy.default, :also_in => @ncbi)
    end

    after(:each) do
      visit("/logout")
    end

    it "should see 'not in hierarchy' message when the user doesn't specify a default hierarchy and page is not in default hierarchy" do
      login_as @user_with_nil_hierarchy
      visit("/pages/#{@ncbi_tc.id}")
      body.should match /Name not in\s*#{Hierarchy.default.label}/
    end

    it "should set the class of the hierarchy select drop-down based on whether a hierarchy is in or out of that hierarchy" do
      login_as @user_with_ncbi_hierarchy
      visit("/pages/#{@ncbi_tc.id}")
      body.should have_tag('select.choose-hierarchy-select') do
        with_tag('option.in', :text => /#{@ncbi.label}/)
        with_tag('option.out', :text => /#{Hierarchy.default.label}/)
      end
    end

    it "should recognize the browsable hierarchy attribute" do
      visit("/pages/#{@taxon_concept.id}")
      body.should have_tag('select.choose-hierarchy-select') do
        with_tag('option[selected=selected]', :text => /#{Hierarchy.default.label}/)
        with_tag('option', :text => /#{@ncbi.label}/)
        with_tag('option', :text => /#{@browsable_hierarchy.label}/)
        without_tag('option', :text => /#{@non_browsable_hierarchy.label}/)
      end
    end

    it "should attribute the default hierarchy when the user doesn't specify one and the page is in both hierarchies" do
      login_as @user_with_nil_hierarchy
      visit("/pages/#{@common_tc.id}")
      body.should have_tag('span.classification-attribution-name', :text => /Species recognized by/) do
        with_tag("a[href^=#{@col_mapping.outlink[:outlink_url]}]")
      end
      body.should have_tag('select.choose-hierarchy-select') do
        with_tag('option[selected=selected]', :text => /#{Hierarchy.default.label}/)
      end
    end

    it "should attribute the default hierarchy when the user has it as the default and page is in both hierarchies" do
      login_as @user_with_default_hierarchy
      visit("/pages/#{@common_tc.id}")
      body.should have_tag('span.classification-attribution-name', :text => /Species recognized by/) do
        with_tag("a[href^=#{@col_mapping.outlink[:outlink_url]}]")
      end
      body.should have_tag('select.choose-hierarchy-select') do
        with_tag('option[selected=selected]', :text => /#{Hierarchy.default.label}/)
      end
    end

    it "should use the label from the NCBI hierarchy when the user has it as the default and page is in both hierarchies" do
      login_as @user_with_ncbi_hierarchy
      visit("/pages/#{@common_tc.id}")
      body.should have_tag('span.classification-attribution-name', :text => /Species recognized by/) do
        with_tag("a[href^=#{@ncbi.agent.homepage.strip}]")
      end
      body.should have_tag('select.choose-hierarchy-select') do
        with_tag('option[selected=selected]', :text => /#{@ncbi.label}/)
      end
    end
  end

  # # Red background/icon on untrusted videos
  # it "should show red background for untrusted video links"
  # it "should not show red background for trusted video links"
  # it "should show red box with 'Videos in red are not trusted.' if there are untrusted videos"
  # it "should not show red box with 'Videos in red are not trusted.' if there are no untrusted videos"
  # it "should show red background around player for untrusted videos"
  # it "should not show red background around player for trusted videos"
  # it "should show red information button if untrusted video plays"
  # it "should show green information button if trusted video plays"
  # it "should show red background for notes area if untrusted video plays"
  # it "should not show red background for notes area if trusted video plays"
  #
  # # LigerCat Medical Concepts Tag Cloud
  # it 'should link to LigerCat when the Medical Concepts content is displayed'
  #   # TODO - this will simply: 1) ensure the TC has a biomedical_terms toc item, 2) load that page with the
  #   # content_id for biomedical_terms, and 3) verify that the page includes the URL we expect.
  #
  # # permalinks for species comments
  # it 'should load comment with the id when comment_id is specified'
  # it 'should hide image when load comment'
  # it 'should have only comments tab active (blue dot)'
  # it 'should not show comment when another tab chosen'
  #
  # #image permalinks
  # it 'should load image as main image when image_id is specified'
  # it 'should paginate to the correct page when image_id is specified and does not exist on the first page of thumbnails'
  # it 'should return 404 page when permalink image_id is specified that doesn\'t exist in the database'
  # it 'should return 404 page when permalink image_id is specified that isn\'t associated with species page'
  # it 'should return 404 page when permalink image_id is specified for an image which is hidden and user which isn\'t a curator'
  # it 'should load hidden image via permalink when user is a curator of the page'
  # it 'should return 404 page when permalink image_id is specified for an image which has been removed'
  # it 'should load removed image via permalink when user is an admin'
  #
  # #text permalinks
  # it 'should switch selected TOC when text_id is specified and not on the default selected TOC'
  # it 'should return 404 page when loading permalink for text which doesn\'t exist in the database'
  # it 'should return 404 page when loading permalink for text which isn\'t associated with species page'
  # it 'should return 404 page when loading permalink for text which is hidden when the user isn\'t a curator'
  # it 'should load hidden text via permalink when user is a curator of the page'
  # it 'should return 404 page when loading permalink for text which has been removed and user isn\'t an admin'
  # it 'should load removed text via permalink when user is an admin'

  it 'should include the TocItem with only unvetted content in it' do
    Capybara.reset_sessions! #previous session influenced this spec
    visit("/pages/#{@id}")
    body.should have_tag('a', :text => /#{@toc_item_with_no_trusted_items.label}/)
  end

  it 'should show info item label for the overview text when there isn\'t an object_title' do
    info_item = InfoItem.find(:first)
    overviews = @taxon_concept.overview
    overviews.each do |data_object|
      data_object.info_items = [info_item]
      data_object.object_title = ""
      data_object.save!
    end
    visit("/pages/#{@id}")
    body.should include(info_item.label)

    # show object_title if it exists
    overviews.each do |data_object|
      data_object.object_title = "Some Title"
      data_object.save!
    end
    visit("/pages/#{@id}")

    body.should include(overviews.first.object_title)
    body.should_not include(info_item.label)
  end

  it 'should show the activity feed' do
    @result.body.should have_tag('ul.feed') do
      with_tag('.feed_item .body', :text => @feed_body_1)
      with_tag('.feed_item .body', :text => @feed_body_2)
      with_tag('.feed_item .body', :text => @feed_body_3)
    end
  end

  it 'should show an empty feed' do
    visit("/pages/#{@exemplar.id}")
    page.body.should have_tag('#activity', :text => /no activity/i)
  end

end
