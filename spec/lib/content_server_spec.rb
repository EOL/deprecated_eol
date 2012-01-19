require File.dirname(__FILE__) + '/../spec_helper'

describe ContentServer do

  before(:all) do
    @old_val = $CONTENT_SERVERS 
    $CONTENT_SERVERS = ['http://c1.org', 'http://c2.org', 'http://c3.org', 'http://c4.org', 'http://c5.org',
      'http://c6.org'].sort
  end

  after(:all) do
    $CONTENT_SERVERS = @old_val
  end

  it 'should cycle through the content servers' do
    results = []
    $CONTENT_SERVERS.length.times do
      results << ContentServer.next
    end
    results.sort.should == $CONTENT_SERVERS
  end

  describe '#logo_path' do

    it 'should build a path (default small png)' do
      url = 'something'
      ContentServer.logo_path(url).should =~ /http.*#{url}_small.png/
    end

    it 'should allow large paths' do
      url = 'something'
      ContentServer.logo_path(url, 'large').should =~ /http.*#{url}_large.png/
    end

    it 'should return blank url if logo url is empty' do
      ContentServer.logo_path('').should == ContentServer.blank
    end

  end

  describe '#cache_path' do

    it 'should use CONTENT_SERVER_CONTENT_PATH by default' do
      ContentServer.should_receive(:cache_url_to_path).with('url').and_return('nice_path')
      ContentServer.cache_path('url').should =~ /http.*c\d.*#{$CONTENT_SERVER_CONTENT_PATH}.*nice_path/
    end
    
    it 'should allow a content host to be specified' do
      ContentServer.should_receive(:cache_url_to_path).with('url').and_return('nice_path')
      ContentServer.cache_path('url', 'http://someotherhost.com/').should =~ /http:\/\/someotherhost\.com\/#{$CONTENT_SERVER_CONTENT_PATH}nice_path/
    end

  end

  describe '#cache_url_to_path' do

    it 'should split up the weird number we pass in' do
      ContentServer.cache_url_to_path(12345678901).should == '/1234/56/78/90/1'
    end

  end

  it 'should know a good default blank image ("/images/blank.gif")' do
    ContentServer.blank.should == "/images/blank.gif"
  end

  describe '#uploaded_content_url' do

    it 'should return blank url if url is empty' do
      ContentServer.uploaded_content_url('', '').should == ContentServer.blank
    end

    it 'should add the extension' do
      ContentServer.uploaded_content_url('whatever', '.ext').should =~ /.ext$/
    end

    it 'should handle the url with #cache_url_to_path' do
      ContentServer.should_receive(:cache_url_to_path).with('whatever').and_return('something')
      ContentServer.uploaded_content_url('whatever', '.ext')
    end

    it 'should start with the next server' do
      ContentServer.should_receive(:next).and_return('nextone')
      ContentServer.uploaded_content_url('whatever', '.ext').should =~ /^nextone/
    end

    it 'should include the CONTENT_SERVER_CONTENT_PATH' do
      ContentServer.uploaded_content_url('whatever', '.ext').should =~ /#{$CONTENT_SERVER_CONTENT_PATH}/
    end

  end

end
