require File.dirname(__FILE__) + '/../spec_helper'

describe 'Mobile' do
  
  before :all do
    load_foundation_cache
    Capybara.reset_sessions!
  end
  
  it 'should redirect a user with a mobile device to the mobile app' do
    open_session # Opens a new session instance
    headers = {"User-Agent" => "iPhone"}
    request_via_redirect(:get, '/', {}, headers) # Allows you to make an HTTP request and follow any subsequent redirects.
    assert_equal '/mobile/contents', path
  end
  
  it 'should have a link for going from mobile to full site' do
    open_session
    headers = {"User-Agent" => "iPhone"}
    visit "/mobile/contents"
    #page.should have_content("<a onclick=\"jQuery.ajax({data:\'\', dataType:\'script\', type:\'post\', url:\'/mobile/contents/disable\'}); return false;\" href=\"#\" class=\"button flip\">Full site</a>\"")
    page.should have_link("Full site")
    click_link("Full site")
  end
  
  it 'should remember user decision to browse the full app' do
    open_session
    headers = {"User-Agent" => "iPhone"}
    page.driver.post('/mobile/contents/disable') #AJAX request fired when user clicks on "Full site"
    page.driver.status_code.should eql 200
    body.should include "window.location.href = \"/\";" #AJAX response redirect to full app homepage
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
    open_session
    headers = {"User-Agent" => "iPhone"}
    page.driver.post('/mobile/contents/enable') #AJAX request fired when user clicks on "Full site"
    page.driver.status_code.should eql 200
    body.should include "window.location.href = \"/mobile/contents\";" #AJAX response redirect to full app homepage
    # TO-DO Test session cookie, something like:   session[:mobile_disabled].should == false
  end
  
end