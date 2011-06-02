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
  
  
  
end