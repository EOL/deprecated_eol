require File.dirname(__FILE__) + '/../spec_helper'

# TODO - these are fragile tests. We should mock the responses: we shouldn't have to be connected to get these, and
# we shouldn't have to change our tests if, say, CNN changes its title.
describe 'Application' do

  it 'should be able to get external page titles' do
    response = get_as_json(fetch_external_page_title_path(:lang => 'en', :url => 'http://eol.org'))
    response.class.should == Hash
    response['message'].should =~ /Encyclopedia of Life/
    response['exception'].should == false
  end

  it 'should not require an http prefix' do
    response = get_as_json(fetch_external_page_title_path(:lang => 'en', :url => 'eol.org'))
    response.class.should == Hash
    response['message'].should =~ /Encyclopedia of Life/
    response['exception'].should == false
  end

  it 'should be able to follow redirects' do
    response = get_as_json(fetch_external_page_title_path(:lang => 'en', :url => 'cnn.com')) # redirects to www.cnn.com
    response.class.should == Hash
    response['message'].should == "CNN.com - Breaking News, U.S., World, Weather, Entertainment &amp; Video News"
    response['exception'].should == false
  end

  it 'should be able to get titles from compressed pages' do
    response = get_as_json(fetch_external_page_title_path(:lang => 'en', :url => 'eol.org')) # our homepage is gzipped
    response.class.should == Hash
    response['message'].should == "Encyclopedia of Life - Animals - Plants - Pictures & Information"
    response['exception'].should == false
  end

  it 'should fail on inaccessible URLs' do
    response = get_as_json(fetch_external_page_title_path(:lang => 'en', :url => 'asgfqrwgqwfwf')) # redirects to www.cnn.com
    response.class.should == Hash
    response['message'].should == "This URL is not accessible"
    response['exception'].should == true
  end

  it 'should give a message if a title is not identified' do
    response = get_as_json(fetch_external_page_title_path(:lang => 'en', :url => 'http://eol.org/assets/v2/logo_index.png')) # its an image
    response.class.should == Hash
    response['message'].should == "Unable to determine the title of this web page"
    response['exception'].should == true
  end

end
