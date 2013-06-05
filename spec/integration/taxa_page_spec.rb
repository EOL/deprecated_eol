require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

# WARNING: Regarding use of subject in this spec, if you are using with_tag you must specify body.should
# due to bug @see https://rspec.lighthouseapp.com/projects/5645/tickets/878-problem-using-with_tag

class TaxonConcept
  def self.missing_id
    missing_id = TaxonConcept.last.id + 1
    while(TaxonConcept.exists?(missing_id)) do
      missing_id += 1
    end
    missing_id
  end
end

def remove_classification_filter_if_used
  begin
    click_on 'Remove classification filter'
  rescue
    nil # Sometimes we're in a hierarchy. Oof.
  end
end

describe 'Taxa page basic tests' do
  before(:all) do
    load_foundation_cache
  end

  it 'should not convert ampersands in preferred common names' do
    tc = build_taxon_concept
    curator = build_curator(tc)
    tc.add_common_name_synonym("Tom & Jerry", :agent => curator.agent, :language => Language.english,
                               :vetted => Vetted.trusted, :preferred => true)
    visit taxon_overview_path(tc.id)
    body.should include('Tom &amp; Jerry')
    body.should_not include('Tom &amp;amp; Jerry')
  end

  it 'should not convert ampersands in preferred common names' do
    tc = build_taxon_concept
    curator = build_curator(tc)
    tc.add_common_name_synonym("Tom&#39;s Jerry", :agent => curator.agent, :language => Language.english,
                               :vetted => Vetted.trusted, :preferred => true)
    visit taxon_overview_path(tc.id)
    body.should include("Tom's Jerry")
    body.should_not include('Tom&#39;s Jerry')
  end

  it 'should not show deleted communities in overview' do
    tc = build_taxon_concept
    collection = Collection.gen
    collection.add(tc)
    community = Community.gen(:name => "This is for testing")
    collection.communities << community
    # published communities will show
    visit taxon_overview_path(tc.id)
    body.should include(community.name)
    # unpublished communities will not show
    community.update_column(:published, false)
    visit taxon_overview_path(tc.id)
    body.should_not include(community.name)
  end

  it 'should not show a structured data summary when there is none' do
    drop_all_virtuoso_graphs
    tc = build_taxon_concept
    visit taxon_overview_path(tc.id)
    body.should_not have_selector("#data_summary table")
  end

  it 'should show a structured data summary when there is user added data' do
    drop_all_virtuoso_graphs
    tc = build_taxon_concept
    @user_added_data = UserAddedData.gen(:subject => tc)
    visit taxon_overview_path(tc.id)
    body.should have_selector("#data_summary table")
  end

  it 'should show a structured data summary when there are measurements' do
    drop_all_virtuoso_graphs
    tc = build_taxon_concept
    @measurement = DataMeasurement.new(:subject => tc, :resource => Resource.gen,
      :predicate => 'http://eol.org/weight', :object => '12345')
    @measurement.update_triplestore
    visit taxon_overview_path(tc.id)
    body.should have_selector("#data_summary table")
  end

  it 'should show a structured data summary when there are associations' do
    drop_all_virtuoso_graphs
    subject_tc = build_taxon_concept
    target_tc = build_taxon_concept
    @association = DataAssociation.new(:subject => subject_tc, :resource => Resource.gen,
      :object => target_tc, :type => 'http://eol.org/preys_on')
    @association.update_triplestore
    visit taxon_overview_path(subject_tc.id)
    body.should have_selector("#data_summary table")
    # target will not have data until an inverse relationship is added
    visit taxon_overview_path(target_tc.id)
    body.should_not have_selector("#data_summary table")
  end

  it 'should show units in the data summary when defined' do
    drop_all_virtuoso_graphs
    tc = build_taxon_concept
    @measurement = DataMeasurement.new(:subject => tc, :resource => Resource.gen,
      :predicate => 'http://eol.org/weight', :object => '12345', :unit => 'http://eol.org/kg')
    @measurement.update_triplestore
    visit taxon_overview_path(tc.id)
    body.should have_selector("#data_summary table")
    body.should include("<td>\n12345")
    body.should_not include("12345<span title=\"http://eol.org/kg\">kilograms")
    KnownUri.gen_if_not_exists(:uri => 'http://eol.org/kg', :name => 'kilograms', :is_unit_of_measure => true)
    visit taxon_overview_path(tc.id)
    body.should include("12345<span title=\"http://eol.org/kg\">kilograms")
  end

end

describe 'Taxa page' do

  before(:all) do
    # so this part of the before :all runs only once
    unless User.find_by_username('testy_taxa_page_spec')
      truncate_all_tables
      load_scenario_with_caching(:testy)
      User.gen(:username => 'testy_taxa_page_spec')
    end
    @testy = EOL::TestInfo.load('testy')
    @taxon_concept = @testy[:taxon_concept]
    @hierarchy_entry = @taxon_concept.published_browsable_hierarchy_entries[0]
    @user = @testy[:user]
    Capybara.reset_sessions!
    Activity.create_defaults
  end

  shared_examples_for 'taxon pages with all expected data' do
    it 'should show the section name' do
      should have_tag('#page_heading h1')
      should include(@section)
    end
    it 'should show the preferred common name titlized properly when site language is English' do
      should have_tag('#page_heading h2')
      should include(@testy[:common_name].capitalize_all_words)
    end
  end

  shared_examples_for 'taxon details tab' do
    it 'should not show unpublished user data objects'
    it 'should only show the most recent revision of a user data object'

    # NOTE - all of these strings come from the scenario loaded above...
    it 'should show text references' do
      should include('A published visible reference for testing.')
    end
    it 'should show doi identifiers for references' do
      # TODO - this is failing in the full suite, and I want to know why.  Caching, prolly.
      should include('A published visible reference with a DOI identifier for testing.')
    end
    it 'should show url identifiers for references' do
      should include('A published visible reference with a URL identifier for testing.')
    end
    it 'should not show invalid identifiers for references' do
      should include('A published visible reference with an invalid identifier for testing.')
      # TODO - really, we'd like to test that the page DOESN'T have a link related to that reference... but I'm not
      # sure how to pull it off with the new (post-upgrade to Rails 3) capybara!
    end
    it 'should not show invisible references' do
      should_not include('A published invisible reference for testing.')
    end
    it 'should not show unpublished references' do
      should_not include('An unpublished visible reference for testing.')
    end
    it 'should show links to literature tab' do
      should have_tag("#toc .section") do
        with_tag("h4 a", :text => "Literature")
        with_tag("ul li a", :text => "Biodiversity Heritage Library")
      end
    end
    it 'should show links to resources tab' do
      should have_tag("#toc .section") do
        with_tag("h4 a", :text => "Resources")
        with_tag("ul li a", :text => "Education resources")
      end
    end
    it 'should not show references container if references do not exist' do
      should_not have_selector('.section .article:nth-child(3) .references')
    end

    it 'should show actions for text objects' do
      should have_selector('div.actions p')
    end

    it 'should show action to set article as an exemplar' do
      should have_selector("div.actions p a", :text => I18n.t(:show_in_overview))
    end

    it 'should show "Add an article or link to this page" button to the logged in users' do
      should have_selector("#page_heading .page_actions li a", :text => "Add an article")
      should have_selector("#page_heading .page_actions li a", :text => "Add a link")
      should have_selector("#page_heading .page_actions li a", :text => "Add to a collection")
    end
  end

  shared_examples_for 'taxon overview tab' do
    it 'should show a gallery of four images' do
      should have_tag("div#media_summary") do
        with_tag("img[src$='#{@taxon_concept.images_from_solr[0].thumb_or_object('580_360')[25..-1]}']")
        with_tag("img[src$='#{@taxon_concept.images_from_solr[1].thumb_or_object('580_360')[25..-1]}']")
        with_tag("img[src$='#{@taxon_concept.images_from_solr[2].thumb_or_object('580_360')[25..-1]}']")
        with_tag("img[src$='#{@taxon_concept.images_from_solr[3].thumb_or_object('580_360')[25..-1]}']")
      end
    end
    it 'should have taxon links for the images in the gallery' do
      (0..3).each do |i|
        should have_selector("a[href='#{taxon_overview_path(@taxon_concept)}']")
      end
    end

    it 'should have sanitized descriptive text alternatives for images in gallery'

    it 'should show IUCN Red List status' do
      should have_tag('div#iucn_status a')
    end

    it 'should show summary text' do
      # TODO: Test the summary text selection logic - as model spec rather than here (?)
      should have_selector('div#text_summary', :text => @testy[:brief_summary_text])
    end

    it 'should show table of contents label when text object title does not exist' do
      should have_selector('h3', :text => @testy[:brief_summary].label)
    end

    it 'should show classifications'
    it 'should show collections'
    it 'should show communities'

    it 'should show curators'
  end

  shared_examples_for 'taxon resources tab' do
    it 'should include About Resources' do
      should include('About Resources')
    end
    it 'should include Partner Links' do
      should include('Partner links')
    end
  end

  shared_examples_for 'taxon community tab' do
    it 'should include Curators' do
      should include('Curators')
    end
    it 'should include Collections' do
      should include('Collections')
    end
    it 'should include Communities' do
      should include('Communities')
    end
  end

  shared_examples_for 'taxon names tab' do
    it 'should list the classifications that recognise the taxon' do
      visit logout_url
      visit taxon_names_path(@taxon_concept)
      body.should have_selector('table.standard.classifications') do |tags|
        tags.should have_selector("a[href='#{taxon_entry_overview_path(@taxon_concept, @taxon_concept.entry)}']")
        tags.should have_selector('td', :text => 'Catalogue of Life')
      end
    end

    it 'should show related names and their sources' do
      visit related_names_taxon_names_path(@taxon_concept)
      # parents
      body.should include(@taxon_concept.hierarchy_entries.first.parent.name.string)
      body.should include(CGI.escapeHTML(@taxon_concept.hierarchy_entries.first.hierarchy.label))
      # children
      body.should include(@testy[:child1].hierarchy_entries.first.name.string)
      body.should include(CGI.escapeHTML(@testy[:child1].hierarchy_entries.first.hierarchy.label))
    end

    it 'should show common names grouped by language with preferred flagged and status indicator' do
      visit common_names_taxon_names_path(@taxon_concept)
      @common_names = EOL::CommonNameDisplay.find_by_taxon_concept_id(@taxon_concept.id)
      # TODO: Test that common names from other languages are present and that current language names appear
      # first after language is switched.
      # English by default
      body.should have_selector('h4', :text => "English")
      body.should match /#{@common_names.first.name_string}/i
      body.should match /#{@common_names.first.agents.first.full_name}/i
      body.should match /#{Vetted.find_by_id(@common_names.first.vetted.id).label}/i
    end

    it 'should allow curators to add common names' do
      visit logout_url
      visit common_names_taxon_names_path(@taxon_concept)
      body.should_not have_selector('form#new_name')
      login_as @testy[:curator]
      visit common_names_taxon_names_path(@taxon_concept)
      body.should have_selector('form#new_name')
      new_name = FactoryGirl.generate(:string)
      fill_in 'Name', :with => new_name
      click_button 'Add name'
      body.should have_selector('td', :text => new_name.capitalize_all_words)
    end

    it 'should allow curators to choose a preferred common name for each language'
    it 'should allow curators to change the status of common names'

    it 'should show synonyms grouped by their source hierarchy' do
      visit logout_url
      visit synonyms_taxon_names_path(@taxon_concept)
      @synonyms = @taxon_concept.published_hierarchy_entries.first.scientific_synonyms
      body.should include(@taxon_concept.published_hierarchy_entries.first.hierarchy.display_title)
      body.should include(@synonyms.first.name.string)
    end
  end

  shared_examples_for 'taxon literature tab' do
    it 'should show some references' do
      should have_selector('.ref_list li')
      @taxon_concept.data_objects.collect(&:refs).flatten.each do |ref|
        if ref.visibility_id == Visibility.invisible.id || ref.published != 1
          should_not include(ref.full_reference)
        else
          should include(ref.full_reference)
        end
      end
    end
  end

  shared_examples_for 'taxon name - taxon_concept page' do
    it 'should show the concepts preferred name style and ' do
      should include(@taxon_concept.entry.name.ranked_canonical_form.string)
    end
  end

  # NOTE - I changed this, since it was failing. It doesn't look like we show the ital name on other pages...
  shared_examples_for 'taxon common name - hierarchy_entry page' do
    it 'should show the concepts preferred name in the heading' do
      should match(/#{@taxon_concept.preferred_common_name_in_language(Language.default)}/i)
    end
  end

  shared_examples_for 'taxon updates tab' do
    it 'should include Taxon newsfeed' do
      should include('Taxon newsfeed')
    end
    it 'should include Page statistics' do
      should include('Page statistics')
    end
  end

  # overview tab - taxon_concept
  context 'overview when taxon has all expected data - taxon_concept' do
    before(:all) do
      EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
      visit taxon_overview_path(@testy[:id])
      @section = 'overview'
      @body = body
    end
    subject { @body }
    it_should_behave_like 'taxon name - taxon_concept page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon overview tab'
    it 'should allow logged in users to post comment in "Latest Updates" section' do
      visit logout_url
      login_as @user
      visit taxon_overview_path(@taxon_concept)
      comment = "Test comment by a logged in user. #{FactoryGirl.generate(:string)}"
      body.should have_selector(".updates .comment #comment_body")
      should have_selector(".updates .comment .actions input[value='Post Comment']")
      fill_in 'comment_body', :with => comment
      click_button "Post Comment"
      current_url.should match /#{taxon_overview_path(@taxon_concept)}/
      body.should include('Comment successfully added')
    end
  end

  # overview tab - hierarchy_entry
  context 'overview when taxon has all expected data - hierarchy_entry' do
    before(:all) do
      EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
      visit taxon_entry_overview_path(@taxon_concept, @hierarchy_entry)
      @section = 'overview'
      @body = body
      # NOTE - these specs *could* leave a classification filter applied when they should not... but seems okay.
    end
    subject { @body }
    it_should_behave_like 'taxon common name - hierarchy_entry page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon overview tab'
  end

  # resources tab - taxon_concept
  context 'resources when taxon has all expected data - taxon_concept' do
    before(:all) do
      visit("/pages/#{@testy[:id]}/resources")
      @section = 'resources'
      @body = body
    end
    subject { @body }
    it_should_behave_like 'taxon name - taxon_concept page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon resources tab'
  end

  # resources tab - hierarchy_entry
  context 'resources when taxon has all expected data - hierarchy_entry' do
    before(:all) do
      visit taxon_entry_resources_path(@taxon_concept, @hierarchy_entry)
      @section = 'resources'
      @body = body
    end
    subject { @body }
    it_should_behave_like 'taxon common name - hierarchy_entry page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon resources tab'
  end

  # details tab - taxon_concept
  context 'details when taxon has all expected data - taxon_concept' do
    before(:all) do
      visit logout_url
      login_as @testy[:curator]
      visit taxon_details_path(@taxon_concept)
      @section = 'details'
      @body = body
    end
    subject { @body }
    it_should_behave_like 'taxon name - taxon_concept page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon details tab'
  end

  # details tab - hierarchy_entry
  context 'details when taxon has all expected data - hierarchy_entry' do
    before(:all) do
      visit logout_url
      login_as @testy[:curator]
      visit taxon_entry_details_path(@taxon_concept, @hierarchy_entry)
      @section = 'details'
      @body = body
    end
    subject { @body }
    it_should_behave_like 'taxon common name - hierarchy_entry page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon details tab'
  end

  # names tab - taxon_concept
  context 'names when taxon has all expected data - taxon_concept' do
    before(:all) do
      visit taxon_names_path(@taxon_concept)
      @section = 'names'
      @body = body
    end
    subject { @body }
    it_should_behave_like 'taxon name - taxon_concept page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon names tab'
  end

  # names tab - hierarchy_entry
  context 'names when taxon has all expected data - hierarchy_entry' do
    before(:all) do
      visit taxon_entry_names_path(@taxon_concept, @hierarchy_entry)
      @section = 'names'
      @body = body
    end
    subject { @body }
    it_should_behave_like 'taxon common name - hierarchy_entry page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon names tab'
  end

  # literature tab - taxon_concept
  context 'literature when taxon has all expected data - taxon_concept' do
    before(:all) do
      visit taxon_literature_path(@taxon_concept)
      @section = 'literature'
      @body = body
    end
    subject { @body }
    it_should_behave_like 'taxon name - taxon_concept page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon literature tab'
  end

  # literature tab - hierarchy_entry
  context 'literature when taxon has all expected data - hierarchy_entry' do
    before(:all) do
      visit taxon_entry_literature_path(@taxon_concept, @hierarchy_entry)
      @section = 'literature'
      @body = body
    end
    subject { @body }
    it_should_behave_like 'taxon common name - hierarchy_entry page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon literature tab'
  end


  # community tab
  context 'community tab' do
    before(:all) do
      visit(taxon_communities_path(@testy[:id]))
      @section = 'community'
      @body = body
    end
    subject { @body }
    it_should_behave_like 'taxon name - taxon_concept page'
    it_should_behave_like 'taxon community tab'
    it "should render communities - curators page" do
      visit(taxon_communities_path(@taxon_concept))
      body.should have_selector("h3", :text => "Communities")
    end
    it "should render communities - collections page" do
      visit(collections_taxon_communities_path(@taxon_concept))
      body.should have_selector("h3", :text => "Collections")
    end
    it "should render communities - curators page" do
      visit(curators_taxon_communities_path(@taxon_concept))
      body.should have_selector("h3", :text => "Curators")
    end
  end


  context 'when taxon does not have any common names' do
    before(:all) do
      visit taxon_overview_path @testy[:taxon_concept_with_no_common_names]
      @body = body
    end
    subject { @body }
    it 'should not show a common name' do
      should_not have_selector('#page_heading h2')
    end
  end

  # @see 'should render when an object has no agents' in old taxa page spec
  context 'when taxon image does not have an agent' do
    it 'should still render the image'
  end

  context 'when taxon does not have any data' do
    it 'details should show empty text' do
      t = TaxonConcept.gen(:published => 1)
      visit taxon_details_path t
      body.should have_selector('#taxon_detail #main .empty')
      body.should match(/No one has contributed any details to this page yet/)
      body.should have_selector("#toc .section") do |tags|
        tags.should have_selector("h4 a[href='#{taxon_literature_path t}']")
        tags.should have_selector("ul li a[href='#{bhl_taxon_literature_path t}']")
      end
    end
  end

  context 'when taxon supercedes another concept' do
    it 'should use supercedure to find taxon if user visits the other concept' do
      visit taxon_overview_path @testy[:superceded_taxon_concept]
      current_url.should match /#{taxon_overview_path(@taxon_concept)}/
      current_url.should_not match /#{taxon_overview_path(@testy[:superceded_taxon_concept])}/
      remove_classification_filter_if_used
      body.should match(/#{@taxon_concept.preferred_common_name_in_language(Language.default)}/i)
      visit taxon_details_path @testy[:superceded_taxon_concept]
      current_url.should match /#{taxon_details_path(@taxon_concept)}/
      current_url.should_not match /#{taxon_details_path(@testy[:superceded_taxon_concept])}/
      body.should match(/#{@taxon_concept.preferred_common_name_in_language(Language.default)}/i)
    end
  end

  context 'when taxon is unpublished' do
    it 'should deny anonymous user' do
      visit logout_path
      lambda { visit taxon_path(@testy[:unpublished_taxon_concept].id) }.should
        raise_error(EOL::Exceptions::MustBeLoggedIn)
    end
    it 'should deny unauthorised user' do
      login_as @user
      referrer = current_url
      lambda { visit taxon_details_path(@testy[:unpublished_taxon_concept].id) }.should
        raise_error(EOL::Exceptions::SecurityViolation)
    end
  end

  context 'when taxon does not exist' do
    it 'should show a missing content error message' do
      lambda { visit("/pages/#{TaxonConcept.missing_id}") }.should raise_error(ActiveRecord::RecordNotFound)
      lambda { visit("/pages/#{TaxonConcept.missing_id}/details") }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'updates tab - taxon_concept' do
    before(:all) do
      visit(taxon_updates_path(@taxon_concept))
      @section = 'updates'
      @body = body
    end
    subject { @body }
    it_should_behave_like 'taxon updates tab'
    it 'should allow logged in users to post comment' do
      visit logout_url
      login_as @user
      visit taxon_updates_path(@taxon_concept)
      comment = "Test comment by a logged in user. #{FactoryGirl.generate(:string)}"
      body.should have_selector("#main .comment #comment_body")
      fill_in 'comment_body', :with => comment
      body.should have_selector("#main .comment .actions input[value='Post Comment']")
      click_button "Post Comment"
      current_url.should match /#{taxon_updates_path(@taxon_concept)}/
      last_comment = Comment.last
      last_comment.body.should == comment
      body.should have_selector("li#Comment-#{last_comment.id}")
    end
  end

  context 'updates tab - hierarchy_entry' do
    before(:all) do
      visit taxon_entry_updates_path(@taxon_concept, @hierarchy_entry)
      @section = 'updates'
      @body = body
    end
    subject { @body }
    it_should_behave_like 'taxon updates tab'
    it 'should allow logged in users to post comment' do
      visit logout_url
      login_as @user
      visit taxon_entry_updates_path(@taxon_concept, @hierarchy_entry)
      comment = "Test comment by a logged in user #{FactoryGirl.generate(:string)}."
      body.should have_selector("#main .comment #comment_body")
      fill_in 'comment_body', :with => comment
      body.should have_selector("#main .comment .actions input[value='Post Comment']")
      click_button "Post Comment"
      current_url.should match /#{taxon_entry_updates_path(@taxon_concept, @hierarchy_entry)}/
      body.should include('Comment successfully added')
    end
  end
end
