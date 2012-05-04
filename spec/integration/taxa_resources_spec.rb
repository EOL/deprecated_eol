require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Taxa page' do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching(:testy)
    @testy = EOL::TestInfo.load('testy')
    @taxon_concept = @testy[:taxon_concept]
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  end
  
  it 'should display Citizen science articles when we have them' do
    # details shouldn't have Citizen Science
    visit taxon_details_path(@taxon_concept)
    body.should_not include('Citizen Science Links')
    
    # resources should have a placeholder, but not content
    visit citizen_science_taxon_resources_path(@taxon_concept)
    body.should include('Citizen Science Links')
    body.should include('No one has contributed any citizen science links to this page yet')
    body.should include('Add a citizen science link to this page')
    
    # add a Citizen Science article and index it
    citizen_science_article = build_data_object('Text', 'This is a Citizen Science links article',
      :published => 1, :vetted => Vetted.trusted, :visibility => Visibility.visible)
    citizen_science_article.toc_items << TocItem.cached_find_translated(:label, 'Citizen Science', 'en')
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
    
    # still shouldn't show up on details tab
    visit taxon_details_path(@taxon_concept)
    body.should_not include('Citizen Science Links')
    body.should_not include(citizen_science_article.description)
    
    # and it should show up on the resources tab
    visit citizen_science_taxon_resources_path(@taxon_concept)
    body.should include('Citizen Science Links')
    body.should include(citizen_science_article.description)
    
  end
end
