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

describe 'Taxa page' do

  before(:all) do
    # so this part of the before :all runs only once
    unless User.find_by_username('testy_scenario')
      truncate_all_tables
      load_scenario_with_caching(:testy)
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
      body.should have_tag('#page_heading h1', /\n.*#{@section}/i)
    end
    it 'should show the preferred common name titlized properly when site language is English' do
      body.should have_tag('#page_heading h2', /^#{@testy[:common_name].capitalize_all_words}/)
    end
  end

  shared_examples_for 'taxon details tab' do
    it 'should not show unpublished user data objects'
    it 'should only show the most recent revision of a user data object'

    it 'should show text references' do
      should have_tag('.references', /A published visible reference for testing./)
    end
    it 'should show doi identifiers for references' do
      body.should have_tag('.references', /A published visible reference with a DOI identifier for testing./) do
        with_tag('a', /dx\.doi\.org/)
      end
    end
    it 'should show url identifiers for references' do
      body.should have_tag('.references', /A published visible reference with a URL identifier for testing./) do
        with_tag('a', /url\.html/)
      end
    end
    it 'should not show invalid identifiers for references' do
      body.should have_tag('.references', /A published visible reference with an invalid identifier for testing./) do
        without_tag('a', /invalid identifier/)
      end
    end
    it 'should not show invisible references' do
      should_not have_tag('.references', /A published invisible reference for testing./)
    end
    it 'should not show unpublished references' do
      should_not have_tag('.references', /An unpublished visible reference for testing./)
    end
    it 'should show links to literature tab' do
      body.should have_tag("#toc .section") do
        with_tag("h4 a", :text => "Literature")
        with_tag("ul li a", :text => "Biodiversity Heritage Library")
      end
    end
    it 'should show links to resources tab' do
      body.should have_tag("#toc .section") do
        with_tag("h4 a", :text => "Resources")
        with_tag("ul li a", :text => "Education resources")
      end
    end
    it 'should not show references container if references do not exist' do
      body.should have_tag('.section .article:nth-child(3)', /brief summary/) do
        without_tag('.references')
      end
    end

    it 'should show actions for text objects' do
      body.should have_tag('div.actions') do
        with_tag('p')
      end
    end

    it 'should show action to set article as an exemplar' do
      body.should have_tag('div.actions p') do
        with_tag("a", :href => "set this article as an exemplar")
      end
    end

    it 'should allow user to rate a text object first then login to complete the action' # do
#      visit logout_url
#      visit taxon_details_path(@taxon_concept)
#      click_link('Change rating to 3 of 5')
#      user = User.gen(:password => 'password')
#      page.fill_in 'session_username_or_email', :with => user.username
#      page.fill_in 'session_password', :with => 'password'
#      click_button 'Sign in'
#      current_url.should match /#{taxon_details_path(@taxon_concept)}/
#      body.should include('Rating was added')
#      visit taxon_details_path(@taxon_concept)
#      click_link('Change rating to 4 of 5')
#      body.should include('Rating was added ')
#    end

    it 'should show "Add an article to this page" button to the logged in users' do
      page.body.should have_tag("#page_heading .page_actions") do
        with_tag("li a", :text => "Add an article to this page")
      end
    end
  end

  shared_examples_for 'taxon overview tab' do
    it 'should show a gallery of four images' do
      body.should have_tag("div#media_summary") do
        with_tag("img[src$=#{@taxon_concept.images_from_solr[0].thumb_or_object('580_360')[25..-1]}]")
        with_tag("img[src$=#{@taxon_concept.images_from_solr[1].thumb_or_object('580_360')[25..-1]}]")
        with_tag("img[src$=#{@taxon_concept.images_from_solr[2].thumb_or_object('580_360')[25..-1]}]")
        with_tag("img[src$=#{@taxon_concept.images_from_solr[3].thumb_or_object('580_360')[25..-1]}]")
      end
    end
    it 'should have taxon links for the images in the gallery' do
      (0..3).each do |i|
        taxon = @taxon_concept.images_from_solr[i].association_with_best_vetted_status.hierarchy_entry.taxon_concept.canonical_form_object.string
        should have_tag('a', :attributes => { :href => overview_taxon_path(@taxon_concept) }, :text => taxon)
      end
    end
    it 'should have sanitized descriptive text alternatives for images in gallery'
      # TODO: add html to testy image description so can test sanitization of alt tags
      # should have_tag('div#media_summary_gallery img[alt^=?]', /(\w+\s){5}/, { :count => 4 })
    it 'should show IUCN Red List status' do
      should have_tag('div#iucn_status a', /.+/)
    end
    it 'should show summary text' do
      # TODO: Test the summary text selection logic - as model spec rather than here (?)
      should have_tag('div#text_summary', /#{@testy[:brief_summary_text]}/)
    end
    it 'should show table of contents label when text object title does not exist' do
      should have_tag('h3', @testy[:brief_summary].label)
    end

    it 'should show classifications'
    it 'should show collections'
    it 'should show communities'

    it 'should show curators' do
      # TODO:
      # body.should have_tag('div#curators_summary') do
      #   with_tag('.details h4', @testy[:curator].full_name)
      # end
    end
  end

  shared_examples_for 'taxon resources tab' do
    it 'should include Identification Resources' do
      body.should include('Identification resources')
    end
    it 'should include Education' do
      body.should include('Education')
    end
    it 'should include Partner Links' do
      body.should include('Partner links')
    end
    it 'should include Citizen science links' do
      body.should include('Citizen science links')
    end
  end

  shared_examples_for 'taxon community tab' do
    it 'should include Curators' do
      body.should include('Curators')
    end
    it 'should include Collections' do
      body.should include('Collections')
    end
    it 'should include Communities' do
      body.should include('Communities')
    end
  end

  shared_examples_for 'taxon names tab' do
    it 'should list the classifications that recognise the taxon' do
      visit logout_url
      visit taxon_names_path(@taxon_concept)
      body.should have_tag('table.standard.classifications') do
        with_tag('a', :href => taxon_hierarchy_entry_overview_path(@taxon_concept, @taxon_concept.entry))
        with_tag('td', /catalogue of life/i)
      end
    end

    it 'should show related names and their sources' do
      visit related_names_taxon_names_path(@taxon_concept)
      # parents
      body.should have_tag('table:first-of-type') do
        with_tag('th:first-of-type', /parent/i)
        with_tag('th:nth-of-type(2)', /source/i)
        with_tag('td:first-of-type', @taxon_concept.hierarchy_entries.first.parent.name.string)
        with_tag('td:nth-of-type(2)', @taxon_concept.hierarchy_entries.first.hierarchy.label)
      end
      # children
      body.should have_tag('table:nth-of-type(2)') do
        with_tag('th:first-of-type', /children/i)
        with_tag('th:nth-of-type(2)', /source/i)
        with_tag('td:first-of-type', @testy[:child1].hierarchy_entries.first.name.string)
        with_tag('td:nth-of-type(2)', @testy[:child1].hierarchy_entries.first.hierarchy.label)
      end
    end

    it 'should show common names grouped by language with preferred flagged and status indicator' do
      visit common_names_taxon_names_path(@taxon_concept)
      @common_names = EOL::CommonNameDisplay.find_by_taxon_concept_id(@taxon_concept.id)
      # TODO: Test that common names from other languages are present and that current language names appear first after language is switched.
      # English by default
      body.should have_tag('h4:first-of-type', "English")
      body.should have_tag('table:first-of-type') do
        with_tag('thead tr th:first-of-type', /name/i)
        with_tag('thead tr th:nth-of-type(2)', /source/i)
        with_tag('thead tr th:nth-of-type(3)', /status/i)
        with_tag('tbody tr:first-of-type td:first-of-type', :attribute => {:class => 'preferred'})
        with_tag('tbody tr:first-of-type td:first-of-type', /#{@common_names.first.name_string}/i)
        with_tag('tbody tr:first-of-type td:nth-of-type(2)', /#{@common_names.first.agents.first.full_name}/i)
        with_tag('tbody tr:first-of-type td:nth-of-type(3)', /#{Vetted.find_by_id(@common_names.first.vetted.id).label}/i)
      end
    end

    it 'should allow curators to add common names' do
      visit logout_url
      visit common_names_taxon_names_path(@taxon_concept)
      body.should_not have_tag('form#new_name')
      login_as @testy[:curator]
      visit common_names_taxon_names_path(@taxon_concept)
      body.should have_tag('form#new_name')
      new_name = FactoryGirl.generate(:string)
      fill_in 'Name', :with => new_name
      select('English', :from => "Language")
      click_button 'Add name'
      body.should have_tag('td', new_name.capitalize_all_words)
    end

    it 'should allow curators to choose a preferred common name for each language'
    it 'should allow curators to change the status of common names'

    it 'should show synonyms grouped by their source hierarchy' do
      visit logout_url
      visit synonyms_taxon_names_path(@taxon_concept)
      @synonyms = @taxon_concept.published_hierarchy_entries.first.scientific_synonyms
      body.should have_tag('h4', /#{@taxon_concept.published_hierarchy_entries.first.hierarchy.display_title}/)
      body.should have_tag('table') do
        with_tag('thead th:first-of-type', /name/i)
        with_tag('thead th:nth-of-type(2)', /relationship/i)
        with_tag('td', /#{@synonyms.first.name.string}/)
      end
    end
  end

  shared_examples_for 'taxon literature tab' do
    it 'should show some references' do
      refs = @taxon_concept.data_objects.collect{|dato| dato.refs.collect{|ref| ref.full_reference}.compact}.flatten.compact
      body.should have_tag('.ref_list') do
        refs.each { |ref| with_tag('li', /ref/) }
      end
    end
  end

  shared_examples_for 'taxon name - taxon_concept page' do
    it 'should show the concepts preferred name style and ' do
      body.should have_tag('#page_heading h1', /#{@taxon_concept.entry.name.ranked_canonical_form.string}/i)
    end
  end

  shared_examples_for 'taxon name - hierarchy_entry page' do
    it 'should show the concepts preferred name in the heading' do
      body.should have_tag('#page_heading h1', /#{@taxon_concept.quick_scientific_name(:normal)}/i)
    end
  end

  shared_examples_for 'taxon updates tab' do
    it 'should include Taxon newsfeed' do
      body.should include('Taxon newsfeed')
    end
    it 'should include Page statistics' do
      body.should include('Page statistics')
    end
  end

  # overview tab - taxon_concept
  context 'overview when taxon has all expected data - taxon_concept' do
    before(:all) do
      EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
      visit("pages/#{@testy[:id]}")
      @section = 'overview'
    end
    subject { body }
    it_should_behave_like 'taxon name - taxon_concept page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon overview tab'
    it 'should allow logged in users to post comment in "Latest Updates" section' do
      visit logout_url
      login_as @user
      visit overview_taxon_path(@taxon_concept)
      comment = "Test comment by a logged in user."
      body.should have_tag(".updates .comment #comment_body")
      should have_tag(".updates .comment .actions input", :val => "Post Comment")
      within(:xpath, '//form[@id="new_comment"]') do
        fill_in 'comment_body', :with => comment
        click_button "Post Comment"
      end
      current_url.should match /#{overview_taxon_path(@taxon_concept)}/
      body.should include('Comment successfully added')
    end
  end

  # overview tab - hierarchy_entry
  context 'overview when taxon has all expected data - hierarchy_entry' do
    before(:all) do
      EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
      visit taxon_hierarchy_entry_overview_path(@taxon_concept, @hierarchy_entry)
      @section = 'overview'
    end
    subject { body }
    it_should_behave_like 'taxon name - hierarchy_entry page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon overview tab'
  end

  # resources tab - taxon_concept
  context 'resources when taxon has all expected data - taxon_concept' do
    before(:all) do
      visit("pages/#{@testy[:id]}/resources")
      @section = 'resources'
    end
    subject { body }
    it_should_behave_like 'taxon name - taxon_concept page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon resources tab'
  end

  # resources tab - hierarchy_entry
  context 'resources when taxon has all expected data - hierarchy_entry' do
    before(:all) do
      visit taxon_hierarchy_entry_resources_path(@taxon_concept, @hierarchy_entry)
      @section = 'resources'
    end
    subject { body }
    it_should_behave_like 'taxon name - hierarchy_entry page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon resources tab'
  end

  # details tab - taxon_concept
  context 'details when taxon has all expected data - taxon_concept' do
    before(:all) do
      visit taxon_details_path(@taxon_concept)
      @section = 'details'
    end
    subject { body }
    it_should_behave_like 'taxon name - taxon_concept page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon details tab'
  end

  # details tab - hierarchy_entry
  context 'details when taxon has all expected data - hierarchy_entry' do
    before(:all) do
      visit taxon_hierarchy_entry_details_path(@taxon_concept, @hierarchy_entry)
      @section = 'details'
    end
    subject { body }
    it_should_behave_like 'taxon name - hierarchy_entry page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon details tab'
  end

  # names tab - taxon_concept
  context 'names when taxon has all expected data - taxon_concept' do
    before(:all) do
      visit taxon_names_path(@taxon_concept)
      @section = 'names'
    end
    subject { body }
    it_should_behave_like 'taxon name - taxon_concept page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon names tab'
  end

  # names tab - hierarchy_entry
  context 'names when taxon has all expected data - hierarchy_entry' do
    before(:all) do
      visit taxon_hierarchy_entry_names_path(@taxon_concept, @hierarchy_entry)
      @section = 'names'
    end
    subject { body }
    it_should_behave_like 'taxon name - hierarchy_entry page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon names tab'
  end

  # literature tab - taxon_concept
  context 'literature when taxon has all expected data - taxon_concept' do
    before(:all) do
      visit taxon_literature_path(@taxon_concept)
      @section = 'literature'
    end
    subject { body }
    it_should_behave_like 'taxon name - taxon_concept page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon literature tab'
  end

  # literature tab - hierarchy_entry
  context 'literature when taxon has all expected data - hierarchy_entry' do
    before(:all) do
      visit taxon_hierarchy_entry_literature_path(@taxon_concept, @hierarchy_entry)
      @section = 'literature'
    end
    subject { body }
    it_should_behave_like 'taxon name - hierarchy_entry page'
    it_should_behave_like 'taxon pages with all expected data'
    it_should_behave_like 'taxon literature tab'
  end


  # community tab
  context 'community tab' do
    before(:all) do
      visit(taxon_community_index_path(@testy[:id]))
      @section = 'community'
    end
    subject { body }
    it_should_behave_like 'taxon name - taxon_concept page'
    it_should_behave_like 'taxon community tab'
    it "should render communities - curators page" do
      visit(taxon_community_index_path(@taxon_concept))
      body.should have_tag("h3", :text => "Communities")
    end
    it "should render communities - collections page" do
      visit(collections_taxon_community_path(@taxon_concept))
      body.should have_tag("h3", :text => "Collections")
    end
    it "should render communities - curators page" do
      visit(curators_taxon_community_path(@taxon_concept))
      body.should have_tag("h3", :text => "Curators")
    end
  end


  context 'when taxon does not have any common names' do
    before(:all) { visit overview_taxon_path @testy[:taxon_concept_with_no_common_names] }
    subject { body }
    it 'should not show a common name' do
      should_not have_tag('#page_heading h2')
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
      body.should have_tag('#taxon_detail #main .empty', /No one has contributed any details to this page yet/)
      body.should have_tag("#toc .section") do
        with_tag("h4 a[href=#{taxon_literature_path t}]")
        with_tag("ul li a[href=#{bhl_taxon_literature_path t}]")
      end
    end
  end

  context 'when taxon supercedes another concept' do
    it 'should use supercedure to find taxon if user visits the other concept' do
      visit overview_taxon_path @testy[:superceded_taxon_concept]
      current_path.should match overview_taxon_path @testy[:id]
      visit taxon_details_path @testy[:superceded_taxon_concept]
      current_path.should match taxon_details_path @testy[:id]
    end
    it 'should show comments from superceded taxa' do
      comment = Comment.gen(:parent_type => "TaxonConcept", :parent_id => @testy[:superceded_taxon_concept].id,
                            :body => "Comment on superceded taxon.",
                            :user => User.first)
      visit overview_taxon_path @testy[:id]
      body.should include("Comment on superceded taxon.")
    end
  end

  context 'when taxon is unpublished' do
    it 'should show anonymous user the login page' do
      visit logout_path
      visit taxon_path(@testy[:unpublished_taxon_concept].id)
      current_path.should == '/login'
      body.should include('You must be logged in to perform this action')
    end
    it 'should show logged in unauthorised user access denied' do
      login_as @user
      referrer = current_url
      visit taxon_details_path(@testy[:unpublished_taxon_concept].id)
      current_url.should == referrer
      body.should include('Access denied')
    end
  end

  context 'when taxon does not exist' do
    it 'should show a missing content error message' do
      visit("/pages/#{TaxonConcept.missing_id}")
      body.should have_tag('h1', /Not found/)
      visit("/pages/#{TaxonConcept.missing_id}/details")
      body.should have_tag('h1', /Not found/)
    end
  end

  context 'updates tab - taxon_concept' do
    before(:all) do
      visit(taxon_update_path(@taxon_concept))
      @section = 'updates'
    end
    subject { body }
    it_should_behave_like 'taxon updates tab'
    it 'should allow logged in users to post comment' do
      visit logout_url
      login_as @user
      visit taxon_update_path(@taxon_concept)
      comment = "Test comment by a logged in user."
      body.should have_tag("#main .comment #comment_body")
      fill_in 'comment_body', :with => comment
      body.should have_tag("#main .comment .actions input", :val => "Post Comment")
      click_button "Post Comment"
      current_url.should match /#{taxon_update_path(@taxon_concept)}/
      body.should include('Comment successfully added')
    end
  end

  context 'updates tab - hierarchy_entry' do
    before(:all) do
      visit taxon_hierarchy_entry_updates_path(@taxon_concept, @hierarchy_entry)
      @section = 'updates'
    end
    subject { body }
    it_should_behave_like 'taxon updates tab'
    it 'should allow logged in users to post comment' do
      visit logout_url
      login_as @user
      visit taxon_hierarchy_entry_updates_path(@taxon_concept, @hierarchy_entry)
      comment = "Test comment by a logged in user."
      body.should have_tag("#main .comment #comment_body")
      fill_in 'comment_body', :with => comment
      body.should have_tag("#main .comment .actions input", :val => "Post Comment")
      click_button "Post Comment"
      current_url.should match /#{taxon_hierarchy_entry_updates_path(@taxon_concept, @hierarchy_entry)}/
      body.should include('Comment successfully added')
    end
  end
end
