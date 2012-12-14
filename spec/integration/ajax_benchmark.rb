require File.dirname(__FILE__) + '/../spec_helper'
require 'capybara'

include ActionController::Caching::Fragments

describe 'Taxon page' do

  before(:all) do
    load_scenario_with_caching(:testy)
    @testy = EOL::TestInfo.load('testy')
    @taxon_concept = @testy[:taxon_concept]
    @times = 3
    @user = EOL::AnonymousUser.new(Language.default)
  end

  def click_around
    begin 
      click_link "Detail"
      click_link "31 Media"
      # TODO - I don't know why these don't work, but they don't work. Says "Missing partial
      # data_objects/data_object_ with {:locale=>[:en], :formats=>[:html], :handlers=>[:erb, :builder, :coffee,
      # :haml]} ... and goes on to say it's looking in gems/ckeditor-3.7.3/app/views ... so that's likely what's
      # causing it (ckeditor), but I'm really not sure... why. These tabs work in development.
      #click_link "#{@taxon_concept.media_count(@user)} Media"
      #click_link "#{@taxon_concept.maps_count} Map#{@taxon_concept.maps_count == 1 ? '' : 's'}"
      click_link "Names"
      click_link "Community"
      click_link "Resources"
      click_link "Literature"
      click_link "Updates"
      click_link "Overview"
    rescue => e
      debugger
      puts "hi"
    end
  end

  it 'should load', :js => true do
    visit overview_taxon_path(@taxon_concept)
    
    Benchmark.bm do |x|
      visit overview_taxon_path(@taxon_concept)
      click_around # warm up cache if needed
      x.report " NO ajax" do
        @times.times { click_around }
      end
      visit overview_taxon_path(@taxon_concept, :a => 1)
      click_around # warm up cache if needed
      x.report " with ajax" do
        @times.times { click_around }
      end
    end
  end

end
