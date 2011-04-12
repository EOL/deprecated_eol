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

describe 'Taxa overview' do

  before(:all) do

    truncate_all_tables
    load_scenario_with_caching(:testy)
    @testy = EOL::TestInfo.load('testy')
    Capybara.reset_sessions!
    HierarchiesContent.delete_all
    @section = 'overview'

  end

  context 'when taxon has all expected data' do
    before { visit("pages/#{@testy[:id]}") }
    subject { body }
    it 'should show the taxon name and section name in the content header' do
      should have_tag('div#content_header_container') do
        with_tag('h1', /^(#{@testy[:scientific_name]})(\n|.)*?(#{@section})$/is)
      end
    end
    it 'should show the preferred common name and common names count in the content header' do
      should have_tag('div#content_header_container') do
        with_tag('p', /^(#{@testy[:common_name]})(\n|.)*?(#{@testy[:taxon_concept].common_names.count})/)
      end
    end
    it 'should show text'
    it 'should show info item label when text object title does not exist'
    it 'should show text references'
    it 'should show doi identifiers for references'
    it 'should show url identifiers for references'
    it 'should not show inappropriate identifiers for references'
    it 'should not show unpublished references'
    it 'should not show invisible references'
    it 'should show images'
    it 'should show classifications'
    it 'should show the '
    it 'should show collections'
    it 'should show communities'
    it 'should show the activity feed' do
      should have_tag('ul.feed') do
        with_tag('.feed_item .body', :text => @testy[:feed_body_1])
        with_tag('.feed_item .body', :text => @testy[:feed_body_2])
        with_tag('.feed_item .body', :text => @testy[:feed_body_3])
      end
    end
    it 'should show curators'
  end

  context 'when taxon does not have any common names' do
    before { visit("/pages/#{@testy[:taxon_concept_with_no_common_names].id}") }
    subject { body }
    it 'should show common name count as 0 in the content header' do
      should have_tag('div#content_header_container') do
        with_tag('p', /^(#{@testy[:taxon_concept_with_no_common_names].common_names.count})/)
      end
    end
  end

  # @see 'should render when an object has no agents' in old taxa page spec
  context 'when taxon image does not have an agent' do
    it 'should still render the image'
  end

  context 'when taxon text exists but it does not have any references' do
    it 'should not show references container'
  end

  context 'when taxon does not have any data' do
    before { visit("/pages/#{@testy[:exemplar].id}") }
    subject { body }
    it 'should show an empty feed' do
      should have_tag('#feed_items_container p.empty', :text => /no activity/i)
    end
  end

  context 'when taxon supercedes another concept' do
    before { visit("/pages/#{@testy[:superceded_taxon_concept].id}") }
    it 'should use supercedure to find taxon if user visits the other concept' do
      current_path.should == "/pages/#{@testy[:id]}"
    end
    # not sure about this one for overview page, should comments show in recent updates feeds?
    # we can use testy[:superceded_taxon_concept] i.e:
    # comment = Comment.gen(:parent_type => "TaxonConcept", :parent_id => @testy[:superceded_taxon_concept].id, :body => "Comment from superceded taxon concept.")
    it 'should show comments from superceded taxa'
  end

  context 'when taxon is unpublished' do
    before { visit("/pages/#{@testy[:unpublished_taxon_concept].id}") }
    subject { body }
    it 'should show unauthorised user an error message in the content header' do
      should have_tag('h1', /^Sorry.*?does not exist/)
    end
  end

  context 'when taxon does not exist' do
    before { visit("/pages/#{TaxonConcept.missing_id}") }
    subject { body }
    it 'should show an error message in the content header' do
      should have_tag('h1', /^Sorry.*?does not exist/)
    end
  end

end
