require File.dirname(__FILE__) + '/../spec_helper'
require('flickr_api')

describe 'FlickrApi' do
  before(:all) do
    if defined? $FLICKR_API_KEY && defined? FLICKR_TOKEN
      @flickr_api = FlickrApi.new(:api_key => FLICKR_API_KEY,
                                  :secret => FLICKR_SECRET,
                                  :auth_frob => FLICKR_FROB,
                                  :auth_token => FLICKR_TOKEN)
      sleep 1
    else
      puts "** WARNING: YOU MUST DEFINE FLICKR_API_KEY (maybe you didn't checkout eol_private)"
      puts "All but one of the following Flickr tests will fail until FLICKR_API_KEY is defined"
    end
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
    rsp = @flickr_api.test_echo
    rsp['stat'].should == 'ok'
    rsp['api_key']['_content'].should == FLICKR_API_KEY
    rsp['format']['_content'].should == 'json'
    rsp['nojsoncallback']['_content'].should == '1'
    rsp['method']['_content'].should == 'flickr.test.echo'
  end

  it 'should return nil of something goes wrong' do
    test_api = FlickrApi.new(:api_key => 'nonsense')
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
    rsp = @flickr_api.auth_get_frob
    rsp['stat'].should == 'ok'
    rsp['frob']['_content'].should match(/^[0-9]+-[0-9a-f]+-[0-9]+$/)
  end

  it 'global token should be valid' do
    rsp = @flickr_api.auth_check_token(FLICKR_TOKEN)
    rsp['stat'].should == 'ok'
    rsp['auth']['token']['_content'].should == FLICKR_TOKEN
    ['write', 'delete'].include?(rsp['auth']['perms']['_content']).should == true
  end

  it 'should get photo information' do
    # http://www.flickr.com/photos/encyclopediaoflife/5416503569/ - a photo I use for testing for EOL
    rsp = @flickr_api.photos_get_info(5416503569)
    rsp['stat'].should == 'ok'
    rsp['photo']['owner']['nsid'].should == '59129167@N06'
    rsp['photo']['owner']['username'].downcase.should == 'EncyclopediaOfLife'.downcase
    rsp['photo']['dateuploaded'].should == '1296858551'
  end

  it 'should list photo comments' do
    rsp = @flickr_api.photos_comments_get_list(5416503569)
    rsp['stat'].should == 'ok'
    rsp['comments']['comment'].last['authorname'].downcase.should == 'EncyclopediaOfLife'.downcase
    rsp['comments']['comment'].last['author'].should == '59129167@N06'
    rsp['comments']['comment'].last['datecreate'].should == '1297202869'
    rsp['comments']['comment'].last['_content'].should == 'test comment'

    # this time with a minimum date
    rsp = @flickr_api.photos_comments_get_list(5416503569, Time.now.to_i)
    rsp['stat'].should == 'ok'
    rsp['comments']['comment'].should == nil
  end

  # # not testing these as I'd rather not have comments go to my photo each
  # # time the tests run. We're also not allowing delete, just write
  # it 'should be able to add comments'
  # it 'should be able to delete comments'
end
