require "spec_helper"

describe ContentServer do

  before(:all) do
    @old_val = $CONTENT_SERVER
    $CONTENT_SERVER = 'http://c1.org'
  end

  after(:all) do
    $CONTENT_SERVER = @old_val
  end

  describe '.cache_path' do

    it 'should use CONTENT_SERVER_CONTENT_PATH by default' do
      ContentServer.should_receive(:cache_url_to_path).with('url').and_return('nice_path')
      ContentServer.cache_path('url').should =~ /http.*c\d.*#{$CONTENT_SERVER_CONTENT_PATH}.*nice_path/
    end
    
    it 'should allow a content host to be specified' do
      ContentServer.should_receive(:cache_url_to_path).with('url').and_return('nice_path')
      ContentServer.cache_path('url', specified_content_host: 'http://someotherhost.com/').should =~ /http:\/\/someotherhost\.com\/#{$CONTENT_SERVER_CONTENT_PATH}nice_path/
    end

  end

  describe '.cache_url_to_path' do

    it 'should split up the weird number we pass in' do
      ContentServer.cache_url_to_path(12345678901).should == '/1234/56/78/90/1'
    end

  end

  it 'should know a good default blank image ("/assets/blank.gif")' do
    ContentServer.blank.should == "/assets/blank.gif"
  end

  describe '.uploaded_content_url' do

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

  describe '.upload_content' do

    let(:ip) { '123.45.67.8' }

    before do
      allow(EOL::Server).to receive(:ip_address) { ip }
      allow(ContentServer).to receive(:call_file_upload_api_with_parameters) { nil }
    end

    it 'gets ip from EOL::Server' do
      allow(EOL::Server).to receive(:ip_address) { ip }
      ContentServer.upload_content('some/path')
      expect(EOL::Server).to have_received(:ip_address)
    end

    # TODO - this spec sucks; it's brittle. That suggests refactoring is needed.
    it 'adds a port to ip' do
      dup = ip.dup
      allow(dup).to receive(:+) { "#{ip}:4321" }
      allow(ip).to receive(:dup) { dup }
      allow(EOL::Server).to receive(:ip_address) { ip }
      ContentServer.upload_content('some/path', '4321')
      expect(dup).to have_received(:+).with(':4321')
    end

    # TODO - this spec sucks; it's brittle. That suggests refactoring is needed.
    it 'does NOT add a port to ip if one is there' do
      ported = "1.2.3.4:56" # NOTE - has port in it
      dup = ported.dup
      allow(dup).to receive(:+) { "#{dup}:4321" }
      allow(EOL::Server).to receive(:ip_address) { ported }
      allow(ported).to receive(:dup) { dup }
      ContentServer.upload_content('some/path', '4321')
      expect(dup).to_not have_received(:+).with(':4321')
    end

    it 'encodes the path' do
      allow(URI).to receive(:encode) { 'changed' }
      ContentServer.upload_content('some/path')
      expect(URI).to have_received(:encode).with('some/path')
    end

    # TODO - Yeah, this also suggests refactoring needed. Config files, anyone?!  :|
    it 'calls a long crappy method with long crappy hard-coded args' do
      allow(ContentServer).to receive(:call_file_upload_api_with_parameters)
      ContentServer.upload_content('some/path')
      expect(ContentServer).to have_received(:call_file_upload_api_with_parameters).
        with("function=upload_content&file_path=http://#{ip}#{URI.encode('some/path')}",
             "content partner logo upload service")
    end

  end

end
