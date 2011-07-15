require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

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
    Capybara.reset_sessions!
    HierarchiesContent.delete_all
    Activity.create_defaults
  end

  shared_examples_for 'taxon pages with all expected data' do
    it 'should show the taxon name and section name' do
      body.should have_tag('#page_heading h1', /#{@testy[:taxon_concept].title_canonical}\n*?.*?#{@section}/i)
    end
    it 'should show the preferred common name' do
      body.should have_tag('#page_heading h2', /^#{@testy[:common_name]}/)
    end
    it 'should show a link to common names with count' do
      body.should have_tag('#page_heading h2 small', /^#{@testy[:taxon_concept].common_names.count}/)
    end
  end

  # overview tab
  context 'overview when taxon has all expected data' do
    before(:all) do
      visit("pages/#{@testy[:id]}")
      @section = 'overview'
    end
    subject { body }
    # WARNING: Regarding use of subject, if you are using with_tag you must specify body.should... due to bug.
    # @see https://rspec.lighthouseapp.com/projects/5645/tickets/878-problem-using-with_tag
    it_should_behave_like 'taxon pages with all expected data'

    it 'should show a gallery of four images' do
      body.should have_tag("div#media_summary") do
        with_tag("img[src$=#{@testy[:taxon_concept].images[0].thumb_or_object('580_360')[25..-1]}]")
        with_tag("img[src$=#{@testy[:taxon_concept].images[1].thumb_or_object('580_360')[25..-1]}]")
        with_tag("img[src$=#{@testy[:taxon_concept].images[2].thumb_or_object('580_360')[25..-1]}]")
        with_tag("img[src$=#{@testy[:taxon_concept].images[3].thumb_or_object('580_360')[25..-1]}]")
      end
      should_not have_tag("img[src$=#{@testy[:taxon_concept].images[4].original_image[25..-1]}]")
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
      body.should have_tag('div#curators_summary') do
        with_tag('.details h4', @testy[:curator].given_name)
      end
    end
  end

  # details tab
  context 'details when taxon has all expected data' do
    before(:all) do
      visit taxon_details_path(@testy[:taxon_concept])
      @section = 'details'
    end
    subject { body }
    it_should_behave_like 'taxon pages with all expected data'

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

    it 'should not show references container if references do not exist' do
      body.should have_tag('.section .article:nth-child(3)', /brief summary/) do
        without_tag('.references')
      end
    end

    it 'should allow user to rate a text object first then login to complete the action' do
      visit logout_url
      visit taxon_details_path(@testy[:taxon_concept])
      click_link('Change rating to 3 of 5')
      user = User.gen(:password => 'password')
      page.fill_in 'user_username', :with => user.username
      page.fill_in 'user_password', :with => 'password'
      click_button 'Login Now »'
      current_url.should match /#{taxon_details_path(@testy[:taxon_concept])}/
      body.should include('Rating was added')
      visit taxon_details_path(@testy[:taxon_concept])
      click_link('Change rating to 4 of 5')
      body.should include('Rating was added ')
    end
  end

  # names tab
  context 'names when taxon has all expected data' do
    before(:all) do
      visit logout_url
      visit taxon_names_path(@testy[:taxon_concept])
      @section = 'names'
    end
    it_should_behave_like 'taxon pages with all expected data'

    it 'should list the classifications that recognise the taxon' do
      visit taxon_names_path(@testy[:taxon_concept])
      body.should have_tag('.article h3', /recognized by the following classifications/i)
      body.should have_tag('.article ul li img[alt=?]', /catalogue of life/i)
      visit common_names_taxon_names_path(@testy[:taxon_concept])
      body.should have_tag('.article h3', /recognized by the following classifications/i)
      body.should have_tag('.article ul li img[alt=?]', /catalogue of life/i)
      visit synonyms_taxon_names_path(@testy[:taxon_concept])
      body.should have_tag('.article h3', /recognized by the following classifications/i)
      body.should have_tag('.article ul li img[alt=?]', /catalogue of life/i)
    end

    it 'should show related names and their sources' do
      visit taxon_names_path(@testy[:taxon_concept])
      # parents
      body.should have_tag('table:first-of-type') do
        with_tag('th:first-of-type', /parent/i)
        with_tag('th:nth-of-type(2)', /source/i)
        with_tag('td:first-of-type', @testy[:taxon_concept].hierarchy_entries.first.parent.name.string)
        with_tag('td:nth-of-type(2)', @testy[:taxon_concept].hierarchy_entries.first.hierarchy.label)
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
      visit common_names_taxon_names_path(@testy[:taxon_concept])
      @common_names = EOL::CommonNameDisplay.find_by_taxon_concept_id(@testy[:taxon_concept].id)
      # TODO: Test that common names from other languages are present and that current language names appear first after language is switched.
      # English by default
      body.should have_tag('h4:first-of-type', "English")
      body.should have_tag('table:first-of-type') do
        with_tag('thead tr th:first-of-type', /preferred/i)
        with_tag('thead tr th:nth-of-type(2)', /name/i)
        with_tag('thead tr th:nth-of-type(3)', /source/i)
        with_tag('thead tr th:nth-of-type(4)', /status/i)
        with_tag('tbody tr:first-of-type td:first-of-type', /#{@common_names.first.preferred ? 'preferred' : 'no'}/i)
        with_tag('tbody tr:first-of-type td:nth-of-type(2)', /#{@common_names.first.name_string}/i)
        with_tag('tbody tr:first-of-type td:nth-of-type(3)', /#{@common_names.first.sources.first.full_name}/i)
        with_tag('tbody tr:first-of-type td:nth-of-type(4)', /#{Vetted.find_by_id(@common_names.first.vetted_id).label}/i)
      end
    end

    it 'should allow curators to add common names' do
      visit logout_url
      visit common_names_taxon_names_path(@testy[:taxon_concept])
      body.should_not have_tag('form#add_common_name')
      login_as @testy[:curator]
      visit common_names_taxon_names_path(@testy[:taxon_concept])
      body.should have_tag('form#add_common_name')
      new_name = 'My new English common name'
      fill_in 'Name', :with => new_name
      select('English', :from => "Name's Language")
      click_button 'Add'
      body.should have_tag('td', new_name)
    end

    it 'should allow curators to choose a preferred common name for each language'
    it 'should allow curators to change the status of common names'

    it 'should show synonyms grouped by their source hierarchy' do
      visit logout_url
      visit synonyms_taxon_names_path(@testy[:taxon_concept])
      @synonyms = @testy[:taxon_concept].published_hierarchy_entries.first.scientific_synonyms
      body.should have_tag('h4', /#{@testy[:taxon_concept].published_hierarchy_entries.first.hierarchy.label}/)
      body.should have_tag('table') do
        with_tag('thead th:first-of-type', /name/i)
        with_tag('thead th:nth-of-type(2)', /relationship/i)
        with_tag('td', /#{@synonyms.first.name.string}/)
      end
    end

  end




#  context 'when taxon does not have any common names'
# TODO: figure out if this should be true and fix/remove as appropriate
#    before(:all) { visit("/pages/#{@testy[:taxon_concept_with_no_common_names].id}") }
#    subject { body }
#    it 'should show common name count as 0' do
#      should have_tag('#page_heading h2 small', /^(#{@testy[:taxon_concept_with_no_common_names].common_names.count})/)
#    end


  # @see 'should render when an object has no agents' in old taxa page spec
  context 'when taxon image does not have an agent' do
    it 'should still render the image'
  end

  context 'when taxon does not have any data' do
    it 'details should show what???'
  end

  context 'when taxon supercedes another concept' do
    it 'should use supercedure to find taxon if user visits the other concept' do
      #visit("/pages/#{@testy[:superceded_taxon_concept].id}")
      #current_path.should match /\/pages\/#{@testy[:id]}/
      visit("/pages/#{@testy[:superceded_taxon_concept].id}/details")
      current_path.should match /\/pages\/#{@testy[:id]}\/details/
    end
  end

  context 'when taxon is unpublished' do
    it 'should show unauthorised user a missing content error message' do
      visit("/pages/#{@testy[:unpublished_taxon_concept].id}")
      body.should have_tag('h2', /^Sorry.*?does not exist/)
      visit("/pages/#{@testy[:unpublished_taxon_concept].id}/details")
      body.should have_tag('h2', /^Sorry.*?does not exist/)
    end
  end

  context 'when taxon does not exist' do
    it 'should show a missing content error message' do
      visit("/pages/#{TaxonConcept.missing_id}")
      body.should have_tag('h2', /Sorry.*?does not exist/)
      visit("/pages/#{TaxonConcept.missing_id}/details")
      body.should have_tag('h2', /Sorry.*?does not exist/)
    end
  end

end
