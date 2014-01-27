require File.dirname(__FILE__) + '/../spec_helper'

# TODO - these are fragile tests. We should mock the responses: we shouldn't have to be connected to get these, and
# we shouldn't have to change our tests if, say, CNN changes its title.
#
# Also, why is this file named features/application_spec ? It's testing #fetch_external_page_title in application_controller, so
# it should be a "controller spec," but also that method really doesn't belong in the controller; it should be in a model, and
# this should be a model spec. This is NOT testing the behavior of the site. ...This spec is just ... misplaced. 
#
# Looking at the method, there's also a ton there that isn't being spec'ed.  :\
describe 'Application' do

  it 'should be able to get external page titles' do
    response = get_as_json(fetch_external_page_title_path(lang: 'en', url: 'http://eol.org'))
    response.class.should == Hash
    response['message'].should =~ /Encyclopedia of Life/
    response['exception'].should == false
  end

  it 'should not require an http prefix' do
    response = get_as_json(fetch_external_page_title_path(lang: 'en', url: 'eol.org'))
    response.class.should == Hash
    response['message'].should =~ /Encyclopedia of Life/
    response['exception'].should == false
  end

  it 'should be able to follow redirects' do
    response = get_as_json(fetch_external_page_title_path(lang: 'en', url: 'cnn.com')) # redirects to www.cnn.com
    response.class.should == Hash
    response['message'].should == "CNN.com - Breaking News, U.S., World, Weather, Entertainment &amp; Video News"
    response['exception'].should == false
  end

  it 'should be able to get titles from compressed pages' do
    response = get_as_json(fetch_external_page_title_path(lang: 'en', url: 'eol.org')) # our homepage is gzipped
    response.class.should == Hash
    response['message'].should == "Encyclopedia of Life - Animals - Plants - Pictures & Information"
    response['exception'].should == false
  end

  it 'should fail on inaccessible URLs' do
    response = get_as_json(fetch_external_page_title_path(lang: 'en', url: 'asgfqrwgqwfwf'))
    response.class.should == Hash
    response['message'].should == "This URL is not accessible"
    response['exception'].should == true
  end

  it 'should give a message if a title is not identified' do
    stub_request(:get, "http://bad.request/something").
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "<nothing here></nothing>", :headers => {})
    response = get_as_json(fetch_external_page_title_path(lang: 'en', url: 'http://bad.request/something'))
    response.class.should == Hash
    response['message'].should == "Unable to determine the title of this web page"
    response['exception'].should == true
  end

end
