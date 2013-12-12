require File.dirname(__FILE__) + '/../spec_helper'
require('flickr_api')

def set_net_http_expectation(name)
  url = @responses[name][0]
  resp = @responses[name][1]
  parsed_url = URI.parse(url)
  URI.should_receive(:parse).with(url).and_return(parsed_url)
  Net::HTTP.should_receive(:get).with(parsed_url).exactly(1).times.and_return(resp)
end

describe 'FlickrApi' do
  before(:all) do
    @now = Time.now.to_i
    # http://www.flickr.com/photos/encyclopediaoflife/5416503569/ - a photo I use for testing for EOL
    @photo_id = 5416503569
    if defined? FLICKR_API_KEY && defined? FLICKR_TOKEN
      @flickr_api = FlickrApi.new(api_key: FLICKR_API_KEY,
                                  secret: FLICKR_SECRET,
                                  auth_frob: FLICKR_FROB,
                                  auth_token: FLICKR_TOKEN)
      sleep 1
    else
      puts "** WARNING: YOU MUST DEFINE FLICKR_API_KEY (maybe you didn't checkout eol_private)"
      puts "All but one of the following Flickr tests will fail until FLICKR_API_KEY is defined"
    end
    @responses = @flickr_api.mock_data(@photo_id, @now) # URLs are only known to the API.  This helps. It's
    # confusing, though, in order to make the code easier to write.  This returns a hash.  The keys are descriptions
    # of which response it contains.  The value is an array: the first member of the array is the URL to expect, and
    # the second is a valid response.
  end

  it 'should create a login url' do
    url = @flickr_api.login_url
    url.should match(FlickrApi::AUTH_API_PREFIX)
    url.should match('api_key=' + FLICKR_API_KEY)
    url.should match('format=json')
    url.should match('nojsoncallback=1')
    url.should match('perms=write')
  end

  it 'should recieve a test echo response' do
    set_net_http_expectation(:echo)
    rsp = @flickr_api.test_echo
    rsp['stat'].should == 'ok'
    rsp['api_key']['_content'].should == FLICKR_API_KEY
    rsp['format']['_content'].should == 'json'
    rsp['nojsoncallback']['_content'].should == '1'
    rsp['method']['_content'].should == 'flickr.test.echo'
  end

  it 'should return nil of something goes wrong' do
    test_api = FlickrApi.new(api_key: 'nonsense')
    error = false
    begin
      rsp = test_api.test_echo
    rescue
      error = true
    end

    error.should == true
    rsp.should == nil
  end

  it 'should recieve an authentication frob' do
    set_net_http_expectation(:frob)
    rsp = @flickr_api.auth_get_frob
    rsp['stat'].should == 'ok'
    rsp['frob']['_content'].should match(/^[0-9]+-[0-9a-f]+-[0-9]+$/)
  end

  it 'global token should be valid' do
    set_net_http_expectation(:token)
    rsp = @flickr_api.auth_check_token(FLICKR_TOKEN)
    rsp['stat'].should == 'ok'
    rsp['auth']['token']['_content'].should == FLICKR_TOKEN
    ['write', 'delete'].include?(rsp['auth']['perms']['_content']).should == true
  end

  it 'should get photo information' do
    set_net_http_expectation(:info)
    rsp = @flickr_api.photos_get_info(@photo_id)
    rsp['stat'].should == 'ok'
    rsp['photo']['owner']['nsid'].should == '59129167@N06'
    rsp['photo']['owner']['username'].downcase.should == 'EncyclopediaOfLife'.downcase
    rsp['photo']['dateuploaded'].should == '1296858551'
  end

  it 'should list photo comments' do
    set_net_http_expectation(:comments)
    rsp = @flickr_api.photos_comments_get_list(@photo_id)
    rsp['stat'].should == 'ok'
    rsp['comments']['comment'].last['authorname'].downcase.should == 'EncyclopediaOfLife'.downcase
    rsp['comments']['comment'].last['author'].should == '59129167@N06'
    rsp['comments']['comment'].last['datecreate'].should == '1302715809'
    rsp['comments']['comment'].last['_content'].should == 'This comment is used for testing the EOL codebase'
  end

  it 'should list photo comments within a minimum date range' do
    set_net_http_expectation(:comments_with_time)
    # ARGH!  The hash being used by #generate_rest_url is coming up with different URLs (the params are in a
    # different order) because of its random order.  So, though I prefer not to, I force it:
    @flickr_api.should_receive(:generate_rest_url).and_return(@responses[:comments_with_time][0])
    rsp = @flickr_api.photos_comments_get_list(@photo_id, @now)
    rsp['stat'].should == 'ok'
    rsp['comments']['comment'].should == nil
  end

  # # not testing these as I'd rather not have comments go to my photo each
  # # time the tests run. We're also not allowing delete, just write
  # it 'should be able to add comments'
  # it 'should be able to delete comments'
end
