require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Mobile redirect' do

  before :all do
    load_foundation_cache
    Capybara.reset_sessions!
  end

  it 'should redirect a user with a mobile device to the mobile app' do
    headers = {"User-Agent" => "iPhone"}
    request_via_redirect(:get, '/', {}, headers) # Allows you to make an HTTP request and follow any subsequent redirects.
    request.fullpath.should == mobile_contents_path # Need to use fullpath because of redirect.  Tricky.
  end

  it 'should have a link for going from mobile to full site' do
    headers = {"User-Agent" => "iPhone"}
    visit "/mobile/contents"
    #page.should have_content("<a onclick=\"jQuery.ajax({data:\'\', dataType:\'script\', type:\'post\', url:\'/mobile/contents/disable\'}); return false;\" href=\"#\" class=\"button flip\">Full site</a>\"")
    page.should have_link("Full site")
    click_link("Full site")
  end

  it 'should remember user decision to browse the full app' do
    headers = {"User-Agent" => "iPhone"}
    page.driver.post('/mobile/contents/disable') #AJAX request fired when user clicks on "Full site"
    page.driver.status_code.should == 302 # "Moved temporarily" for redirect.
    body.should include root_path #AJAX response redirect to full app homepage
    # TO-DO Test session cookie, something like:   session[:mobile_disabled].should == true

    ###############################################
    #OLD attempts - keeping them for reference
    #{:post => "/mobile/contents/disable"}.should route_to(:controller => "mobile/contents", :action => "disable")
    #--------------
    #visit("/mobile/contents/disable", :method => :post)
    #response.should be_redirect
    #--------------
    #visit("/mobile/contents/disable", :method => :post)
    #should route_to(:controller => "mobile/contents", :action => "disable")
    #--------------
    #visit "/mobile/contents"
    #visit("/mobile/contents/disable", :method => :post)
    #assert_equal '/', path
    #response.should redirect_to('/')
    #body.should include "Global access to knowledge about life on Earth"
    #--------------
    #cookies = Capybara.current_session.driver.current_session.instance_variable_get(:@rack_mock_session).cookie_jar
    #cookies[:mobile_disabled].should be_nil
    ###############################################
  end

  it 'should remember user decision to browse the mobile app' do
    headers = {"User-Agent" => "iPhone"}
    page.driver.post('/mobile/contents/enable') #AJAX request fired when user clicks on "Full site"
    page.driver.status_code.should eql 200
    body.should include "window.location.href = \"/mobile/contents\";" #AJAX response redirect to full app homepage
    # TO-DO Test session cookie, something like:   session[:mobile_disabled].should == false
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
    HierarchiesContent.delete_all
    @section = 'overview'
  end

  it 'should show the static contents index' do
    headers = {"User-Agent" => "iPhone"}
    visit "/mobile/contents"
    body.should have_tag("ul#static_taxa_index") do
      with_tag("li:first-child", I18n.t("mobile.contents.taxa"))
      with_tag("li:nth-child(2)") do
        with_tag("a")
      end
    end
  end

  it 'should show a taxon overview when clicking on an item of the taxa index' do
    headers = {"User-Agent" => "iPhone"}
    visit "/mobile/contents"
    click_link "Nihileri voluptasus" do # TODO - this name shouldn't be hard-coded.
      response.should be_ok
      current_path.should == mobile_taxon_path(@taxon_concept.id)
      body.should have_tag("h1", I18n.t("mobile.taxa.taxon_overview"))
      body.should have_tag("h3", @taxon_concept.quick_scientific_name)
    end
  end

  it 'should show an example taxon overview' do

    # visit("mobile/taxa/#{@testy[:id]}")
    # raise body.inspect
    # body.should have_tag("h1", I18n.t("mobile.taxa.taxon_overview"))

    headers = {"User-Agent" => "iPhone"}
    visit mobile_taxon_path(@taxon_concept.id)
    current_path.should == mobile_taxon_path(@taxon_concept.id)
    body.should have_tag("h1", I18n.t("mobile.taxa.taxon_overview"))
    body.should have_tag("h3", @taxon_concept.quick_scientific_name)
  end

  it 'should show an example taxon details' do
    headers = {"User-Agent" => "iPhone"}
    visit details_mobile_taxon_path(@taxon_concept.id)
    current_path.should == details_mobile_taxon_path(@taxon_concept.id)
    body.should have_tag("h1", I18n.t("mobile.taxa.taxon_details"))
    body.should have_tag("h3", @taxon_concept.quick_scientific_name)
  end

  it 'should show an example taxon media gallery' do
    headers = {"User-Agent" => "iPhone"}
    visit media_mobile_taxon_path(@taxon_concept.id)
    current_path.should == media_mobile_taxon_path(@taxon_concept.id)
    body.should have_tag("h1", I18n.t("mobile.taxa.taxon_media"))
    body.should have_tag("h3", @taxon_concept.quick_scientific_name)
  end


end
