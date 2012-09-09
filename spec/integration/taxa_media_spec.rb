require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Taxa media' do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :media_heavy
    @data = EOL::TestInfo.load('media_heavy')
    @taxon_concept = @data[:taxon_concept]
    Capybara.reset_sessions!
    CuratorLevel.create_defaults
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  end

  it 'should show the taxon header' do
    visit taxon_media_path(@taxon_concept)
    body.should have_selector('#page_heading') do
      with_tag('h1', /(#{@taxon_concept.title_canonical})(\n|.)*?media/i)
    end
  end

  it 'should show a gallery of mixed media' do
    visit taxon_media_path(@taxon_concept)
    body.should have_selector("li.sound")
    body.should have_selector("li.video")
    body.should have_selector("li.image")
  end

end
