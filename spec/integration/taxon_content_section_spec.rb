require File.dirname(__FILE__) + '/../spec_helper'

describe 'Taxa page (HTML)' do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching(:testy)
    @testy = EOL::TestInfo.load('testy')
    Capybara.reset_sessions!
    make_all_nested_sets
    flatten_hierarchies
    visit("/pages/#{@testy[:id]}")
    @page = page.body
  end

  it 'should list all of the content sections' do
    @page.should have_tag('h2', :text => 'Content Navigation') do
      with_tag('ul#content_navigation') do
        TaxonContentSection.all.each do |section|
          with_tag('li', :text => section.name)
        end
      end
    end
  end

  it 'should render the overview by default' do
    @page.should have_tag('h2', :text => 'Content Navigation') do
      with_tag('ul#content_navigation') do
        #TODO
      end
    end
  end

end
