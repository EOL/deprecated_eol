require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../lib/eol_data'
require 'nokogiri'

class EOL::NestedSet; end
EOL::NestedSet.send :extend, EOL::Data
require 'solr_api'

if $ENABLE_MOBILE

  describe 'Mobile redirect' do

    before(:all) do
      # so this part of the before :all runs only once
      unless User.find_by_username('testy_scenario')
        truncate_all_tables
        load_scenario_with_caching(:testy)
      end
      @testy = EOL::TestInfo.load('testy')
      @taxon_concept = @testy[:taxon_concept]
      Capybara.reset_sessions!
      @section = 'overview'
    end

    it 'should redirect a user with a mobile device to the mobile app' do
      headers = {"User-Agent" => "iPhone"}
      request_via_redirect(:get, '/', {}, headers) # Allows you to make an HTTP request and follow any subsequent redirects.
      request.fullpath.should == mobile_contents_path # Need to use fullpath because of redirect.  Tricky.
    end

    it 'should remember user decision to browse the full app' do
      headers = {"User-Agent" => "iPhone"}
      page.driver.post('/mobile/contents/disable') #AJAX request fired when user clicks on "Full site"
      page.driver.status_code.should == 302 # "Moved temporarily" for redirect.
      body.should include root_path #AJAX response redirect to full app homepage
      # TO-DO Test session cookie, something like:   session[:mobile_disabled].should == true
    end

    it 'should remember user decision to browse the mobile app' do
      headers = {"User-Agent" => "iPhone"}
      page.driver.post('/mobile/contents/enable') #AJAX request fired when user clicks on "Full site"
      page.driver.status_code.should == 302 # "Moved temporarily" for redirect.
      body.should include mobile_contents_path #AJAX response redirect to full app homepage
      # TO-DO Test session cookie, something like:   session[:mobile_disabled].should == false
    end

    it 'should have a link for going from mobile to full site' do
      headers = {"User-Agent" => "iPhone"}
      visit mobile_contents_path
      body.should_not include "We're sorry but an error has occurred"
      page.should have_link(I18n.t("mobile.contents.full_site"))
      # click_link(I18n.t("mobile.contents.full_site"))
    end

    it 'should translate url and redirect to mobile taxon overview' do
      headers = {"User-Agent" => "iPhone"}
      request_via_redirect(:get, "/pages/#{@taxon_concept.id}/overview", {}, headers)
      request.fullpath.should == mobile_taxon_path(@taxon_concept.id)
    end

    it 'should translate url and redirect to mobile taxon details' do
      headers = {"User-Agent" => "iPhone"}
      request_via_redirect(:get, "/pages/#{@taxon_concept.id}/details", {}, headers)
      request.fullpath.should == mobile_taxon_details_path(@taxon_concept.id)
    end

    it 'should translate url and redirect to mobile taxon media' do
      headers = {"User-Agent" => "iPhone"}
      request_via_redirect(:get, "/pages/#{@taxon_concept.id}/media", {}, headers)
      request.fullpath.should == mobile_taxon_media_path(@taxon_concept.id)
    end


  end

  describe 'Mobile taxa browsing' do

    before(:all) do
      # so this part of the before :all runs only once
      unless User.find_by_username('testy_scenario')
        truncate_all_tables
        load_scenario_with_caching(:testy)
      end
      @testy = EOL::TestInfo.load('testy')
      @taxon_concept = @testy[:taxon_concept]
      Capybara.reset_sessions!
      @section = 'overview'
    end

    # This test sometime passes, sometimes not. Pure random behaviour. Maybe sync problems.
    it 'should show a random species index' do
      headers = {"User-Agent" => "iPhone"}
      visit mobile_contents_path
      sleep 2 # this seems to solve sync problems
      body.should have_tag("ul#random_taxa_index") do
        with_tag("li:first-child", I18n.t("mobile.contents.explore_eol"))
        # with_tag("li:nth-child(2)") do
        #   with_tag("a")
        # end
      end
    end

    # Sometime fails for sync problems
    it 'should show a taxon overview when clicking on an item of the taxa index' do
      pending "Test working but disabled for compatibility issues on some machines with Selenium"
      Capybara.current_driver = :selenium  # temporarily select different driver
      headers = {"User-Agent" => "iPhone"}
      visit "/mobile/contents"
      sleep 2
      find(:xpath, "/html/body/div/div[2]/ul/li[2]/div/div/a").click # first link of random species
      sleep 5
      body.should have_tag("h1", I18n.t("mobile.taxa.taxon_overview"))
      Capybara.current_driver = :rack_test  # switch back to default driver
    end

    it 'should show an example taxon overview' do
      Capybara.current_driver = :rack_test # Forcing back to rack_test
      headers = {"User-Agent" => "iPhone"}
      visit mobile_taxon_path(@taxon_concept.id)
      current_path.should == mobile_taxon_path(@taxon_concept.id)
      body.should have_tag("h1", I18n.t("mobile.taxa.taxon_overview"))
      body.should have_tag("h3", @taxon_concept.quick_scientific_name)
    end

    it 'should show an example taxon details' do
      headers = {"User-Agent" => "iPhone"}
      visit mobile_taxon_details_path(@taxon_concept.id)
      current_path.should == mobile_taxon_details_path(@taxon_concept.id)
      body.should have_tag("h1", I18n.t("mobile.taxa.taxon_details"))
      body.should have_tag("h3", @taxon_concept.quick_scientific_name)
    end

    it 'should show an example taxon media gallery' do
      headers = {"User-Agent" => "iPhone"}
      visit mobile_taxon_media_path(@taxon_concept.id)
      current_path.should == mobile_taxon_media_path(@taxon_concept.id)
      body.should have_tag("h1", I18n.t("mobile.taxa.taxon_media"))
      body.should have_tag("h3", @taxon_concept.quick_scientific_name)
    end
  end

  describe 'Mobile search' do

    before :all do
      truncate_all_tables
      load_scenario_with_caching(:search_names)
      data = EOL::TestInfo.load('search_names')

      @panda                      = data[:panda]
      @name_for_all_types         = data[:name_for_all_types]
      @name_for_multiple_species  = data[:name_for_multiple_species]
      @unique_taxon_name          = data[:unique_taxon_name]
      @text_description           = data[:text_description]
      @image_description          = data[:image_description]
      @video_description          = data[:video_description]
      @sound_description          = data[:sound_description]
      @tiger_name                 = data[:tiger_name]
      @tiger                      = data[:tiger]
      @tiger_lilly_name           = data[:tiger_lilly_name]
      @tiger_lilly                = data[:tiger_lilly]
      @tricky_search_suggestion   = data[:tricky_search_suggestion]
      @suggested_taxon_name       = data[:suggested_taxon_name]
      @user1                      = data[:user1]
      @user2                      = data[:user2]
      @community                  = data[:community]
      @collection                 = data[:collection]

      Capybara.reset_sessions!
      visit('/logout')
      make_all_nested_sets
      flatten_hierarchies
      EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
    end

    it 'should show a search field on mobile home page' do
      pending "Test working but disabled for compatibility issues on some machines with Selenium"
      Capybara.current_driver = :selenium # temporarily select different driver
      headers = {"User-Agent" => "iPhone"}
      visit "/mobile/contents"
      body.should have_tag("form", :method => "get", :action => "/mobile/search/")
      body.should have_tag("input", :type => "search", :name => "mobile_search", :id => "search_field")
      fill_in 'search_field', :with => @tiger_name
      page.evaluate_script("document.forms[0].submit()")
      #find_field('search_field').node.send_keys(:return)
      body.should have_tag("h2", I18n.t("mobile.search.results"))
      Capybara.current_driver = :rack_test  # switch back to default driver
    end

    it 'should redirect to taxon overview page if only one match is found' do
      headers = {"User-Agent" => "iPhone"}
      visit("/mobile/search?mobile_search=#{@unique_taxon_name}")
      current_path.should == mobile_taxon_path(@panda)
      body.should have_tag("h1", I18n.t("mobile.taxa.taxon_overview"))
      body.should have_tag("h3", @panda.title)
    end

    it 'should search for an invalid term and provide a suggestion' do
      pending "Need to find a term to search that returns the suggestion page \'Did you mean..\'"
      headers = {"User-Agent" => "iPhone"}
      visit("/mobile/search?mobile_search=#{@tricky_search_suggestion}")
      body.should_not include "We're sorry but an error has occurred"
      body.should have_tag('h2', 'Suggestions')
      body.should have_content('Did you mean:')
    end

    it 'should return a helpful message if no results' do
      headers = {"User-Agent" => "iPhone"}
      visit("/mobile/search?mobile_search=bozo")
      body.should have_tag('h2', I18n.t("mobile.search.no_results_found"))
    end

    it 'should return a list of results' do
      headers = {"User-Agent" => "iPhone"}
      visit("/mobile/search?mobile_search=#{@tiger_name}")
      body.should have_tag('h2', I18n.t("mobile.search.results"))
      body.should have_tag('li.result_item')
      # To-do look for results - now it seems to find different things..
      #body.should include "#{@tiger_name}"
      #body.should include "#{@tiger_lilly_name}"
    end

  end

end
