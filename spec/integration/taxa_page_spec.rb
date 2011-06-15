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
    @section = 'overview'
  end

  context 'overview when taxon has all expected data' do
    before(:all) { visit("pages/#{@testy[:id]}") }
    subject { body }
    # WARNING: Regarding use of subject, if you are using with_tag you must specify body.should... due to bug.
    # @see https://rspec.lighthouseapp.com/projects/5645/tickets/878-problem-using-with_tag

    it 'should show the taxon name and section name' do
      should have_tag('#page_heading h1', /(#{@testy[:taxon_concept].title_canonical})(\n|.)*?(#{@section})/i)
    end
    it 'should show the preferred common name' do
      should have_tag('#page_heading h2', /^#{@testy[:common_name]}/)
    end
    it 'should show a link to common names with count' do
      should have_tag('#page_heading h2 small', /^#{@testy[:taxon_concept].common_names.count}/)
    end
    it 'should show a gallery of four images' do
      body.should have_tag("div#media_summary") do
        with_tag("img[src$=#{@testy[:taxon_concept].images[0].original_image[25..-1]}]")
        with_tag("img[src$=#{@testy[:taxon_concept].images[1].original_image[25..-1]}]")
        with_tag("img[src$=#{@testy[:taxon_concept].images[2].original_image[25..-1]}]")
        with_tag("img[src$=#{@testy[:taxon_concept].images[3].original_image[25..-1]}]")
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
    it 'should show the activity feed' do
      body.should have_tag('#feed_items ul') do
        with_tag('.details', /#{@testy[:feed_body_1]}/)
        with_tag('.details', /#{@testy[:feed_body_2]}/)
        with_tag('.details', /#{@testy[:feed_body_3]}/)
      end
    end
    it 'should show curators' do
      body.should have_tag('div#curators_summary') do
        with_tag('.details h4', @testy[:curator].given_name)
      end
    end
  end

  context 'details when taxon has all expected data' do
    before(:all) { visit("pages/#{@testy[:id]}/details") }
    subject { body }
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

    it 'should allow user to rate a text object first then login to complete the action'
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
    it 'overview should show an empty feed' do
      visit("/pages/#{@testy[:exemplar].id}")
      body.should have_tag('#feed_items p.empty', /no activity/i)
    end
    it 'details should show what???'
  end

  context 'when taxon supercedes another concept' do
    it 'should use supercedure to find taxon if user visits the other concept' do
      #visit("/pages/#{@testy[:superceded_taxon_concept].id}")
      #current_path.should match /\/pages\/#{@testy[:id]}/
      visit("/pages/#{@testy[:superceded_taxon_concept].id}/details")
      current_path.should match /\/pages\/#{@testy[:id]}\/details/
    end
    # not sure about this one for overview page, should comments show in recent updates feeds?
    # we can use testy[:superceded_taxon_concept] i.e:
    # comment = Comment.gen(:parent_type => "TaxonConcept", :parent_id => @testy[:superceded_taxon_concept].id, :body => "Comment from superceded taxon concept.")
    it 'should show comments from superceded taxa'
  end

  context 'when taxon is unpublished' do
    it 'should show unauthorised user an error message in the content header' do
      visit("/pages/#{@testy[:unpublished_taxon_concept].id}")
      body.should have_tag('h1', /^Sorry.*?does not exist/)
      visit("/pages/#{@testy[:unpublished_taxon_concept].id}/details")
      body.should have_tag('h1', /^Sorry.*?does not exist/)
    end
  end

  context 'when taxon does not exist' do
    it 'should show an error message in the content header' do
      visit("/pages/#{TaxonConcept.missing_id}")
      body.should have_tag('h1', /Sorry.*?does not exist/)
      visit("/pages/#{TaxonConcept.missing_id}/details")
      body.should have_tag('h1', /Sorry.*?does not exist/)
    end
  end

end
