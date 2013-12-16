require File.dirname(__FILE__) + '/../spec_helper'

describe ContentServer do

  before(:all) do
    @old_val = $CONTENT_SERVER
    $CONTENT_SERVER = 'http://c1.org'
  end

  after(:all) do
    $CONTENT_SERVER = @old_val
  end

  describe '#cache_path' do

    it 'should use CONTENT_SERVER_CONTENT_PATH by default' do
      ContentServer.should_receive(:cache_url_to_path).with('url').and_return('nice_path')
      ContentServer.cache_path('url').should =~ /http.*c\d.*#{$CONTENT_SERVER_CONTENT_PATH}.*nice_path/
    end
    
    it 'should allow a content host to be specified' do
      ContentServer.should_receive(:cache_url_to_path).with('url').and_return('nice_path')
      ContentServer.cache_path('url', specified_content_host: 'http://someotherhost.com/').should =~ /http:\/\/someotherhost\.com\/#{$CONTENT_SERVER_CONTENT_PATH}nice_path/
    end

  end

  describe '#cache_url_to_path' do

    it 'should split up the weird number we pass in' do
      ContentServer.cache_url_to_path(12345678901).should == '/1234/56/78/90/1'
    end

  end

  it 'should know a good default blank image ("/assets/blank.gif")' do
    ContentServer.blank.should == "/assets/blank.gif"
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

    it 'should start with the content server' do
      ContentServer.uploaded_content_url('whatever', '.ext').should =~ /^#{$SINGLE_DOMAIN_CONTENT_SERVER}/
    end

    it 'should include the CONTENT_SERVER_CONTENT_PATH' do
      ContentServer.uploaded_content_url('whatever', '.ext').should =~ /#{$CONTENT_SERVER_CONTENT_PATH}/
    end

  end

end
