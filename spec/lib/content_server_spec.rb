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
      allow(ContentServer).to receive(:call_file_upload_api_with_parameters)
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

  describe '.upload_resource' do

    let(:xml) { '<xml><tags/></xml>' }
    let(:hash) { { "response" => { "status" => 'validated' } } }

    before do
      allow(ContentServer).to receive(:call_api_with_parameters) { xml }
      allow(Hash).to receive(:from_xml) { hash }
      allow(ResourceStatus).to receive(:validation_failed) { 'failed' }
      allow(ResourceStatus).to receive(:validated) { 'validated' }
      allow(ErrorLog).to receive(:create)
    end

    it 'returns nil without file url' do
      expect(ContentServer.upload_resource(nil, 'whatever')).to be_nil
    end

    it 'returns nil without resource id' do
      expect(ContentServer.upload_resource('whatever', nil)).to be_nil
    end

    # TODO - this probably shouldn't be hard-coded this way.
    it 'calls the API with hard-coded params' do
      allow(ContentServer).to receive(:call_api_with_parameters) { xml }
      ContentServer.upload_resource('hello', 'friend')
      expect(ContentServer).to have_received(:call_api_with_parameters).
        with("function=upload_resource&resource_id=friend&file_path=hello",
             "content partner dataset service")
    end

    it 'finds and return a resource status based on response' do
      allow(Hash).to receive(:from_xml) { { "response" => { "status" => "some name" } } }
      allow(ResourceStatus).to receive(:some_name) { 'retval' }
      expect(ContentServer.upload_resource('hello', 'friend').first).to eq('retval')
      expect(ResourceStatus).to have_received(:some_name)
    end

    # NOTE that this does not test the params of the error log. I didn't care enough, would be ugly.
    it 'creates an error log if the status is not validated' do
      allow(Hash).to receive(:from_xml) { { "response" => { "status" => "some name" } } }
      allow(ResourceStatus).to receive(:some_name) { 'retval' }
      ContentServer.upload_resource('hello', 'friend')
      expect(ErrorLog).to have_received(:create)
    end

    it 'returns the error if there was one in response' do
      allow(Hash).to receive(:from_xml) { { "response" => { "status" => "validated", "error" => "too useful" } } }
      allow(ResourceStatus).to receive(:some_name) { 'retval' }
      expect(ContentServer.upload_resource('hello', 'friend').second).to eq("too useful")
    end

    context "response only has an error" do

      before do
        allow(Hash).to receive(:from_xml) { { "response" => { "error" => "bad" } } }
      end

      subject { ContentServer.upload_resource('hello', 'friend') }
      
      it 'returns validation_failed' do
        expect(subject.first).to eq('failed')
      end

      it 'logs an error' do
        allow(ErrorLog).to receive(:create)
        subject # Calls it.
        expect(ErrorLog).to have_received(:create)
      end

      # NOTE - I added this. It was returning nil before, and not using the error at all. Lame?
      it 'returns the error' do
        expect(subject.second).to eq('bad')
      end

    end

    it 'returns validation failure (with nil error) if response is empty' do
      allow(Hash).to receive(:from_xml) { { "response" => {} } }
      expect(ContentServer.upload_resource('hello', 'friend')).to eq(['failed', nil])
    end

  end

  describe '.update_data_object_crop' do

    let(:env) { "whatever" }

    # TODO - BAD SMELLS ABOUND.
    before do
      allow(Rails).to receive(:env) { env }
      allow(env).to receive(:staging_dev?) { false }
      allow(env).to receive(:bocce_demo_dev?) { false }
      allow(ContentServer).to receive(:call_file_upload_api_with_parameters)
    end

    it 'returns nil if any arg is blank' do
      expect(ContentServer.update_data_object_crop('', 'a', 'b', 'c')).to be_nil
      expect(ContentServer.update_data_object_crop('a', '', 'b', 'c')).to be_nil
      expect(ContentServer.update_data_object_crop('a', 'b', '', 'c')).to be_nil
      expect(ContentServer.update_data_object_crop('a', 'b', 'c', '')).to be_nil
      expect(ContentServer).to_not have_received(:call_file_upload_api_with_parameters)
    end

    context 'reasonable args' do

      subject { ContentServer.update_data_object_crop(123654, 23, 45, 67) }

      it 'builds expected params' do
        allow(ContentServer).to receive(:call_file_upload_api_with_parameters)
        subject # Calls it.
        expect(ContentServer).to have_received(:call_file_upload_api_with_parameters).
          with("function=crop_image_pct&data_object_id=123654&x=23&y=45&w=67&ENV_NAME=whatever",
               "update data object crop service")
      end

      it 'changes staging_dev to staging' do
        allow(env).to receive(:staging_dev?) { true }
        allow(ContentServer).to receive(:call_file_upload_api_with_parameters)
        subject # Calls it.
        expect(ContentServer).to have_received(:call_file_upload_api_with_parameters).
          with("function=crop_image_pct&data_object_id=123654&x=23&y=45&w=67&ENV_NAME=staging",
               "update data object crop service")
      end

      it 'changes bocce_demo_dev to bocce_demo' do
        allow(env).to receive(:bocce_demo_dev?) { true }
        allow(ContentServer).to receive(:call_file_upload_api_with_parameters)
        subject # Calls it.
        expect(ContentServer).to have_received(:call_file_upload_api_with_parameters).
          with("function=crop_image_pct&data_object_id=123654&x=23&y=45&w=67&ENV_NAME=bocce_demo",
               "update data object crop service")
      end

    end

  end

  describe ".upload_data_search_file" do

    before do
      allow(Rails.configuration).to receive(:local_services)
      allow(ContentServer).to receive(:call_file_upload_api_with_parameters)
    end

    it 'returns nil if args blank' do
      expect(ContentServer.upload_data_search_file('', 'foo')).to be_nil
      expect(ContentServer.upload_data_search_file('foo', '')).to be_nil
      expect(ContentServer).to_not have_received(:call_file_upload_api_with_parameters)
    end

    it 'returns the first arg if local_services enabled' do
      allow(Rails.configuration).to receive(:local_services) { true }
      expect(ContentServer.upload_data_search_file('file/path', 'a')).to eq('file/path')
    end

    it 'calls upload api with hard-coded stuff' do
      ContentServer.upload_data_search_file('file/path', 4365)
      expect(ContentServer).to have_received(:call_file_upload_api_with_parameters).
        with("function=upload_dataset&data_search_file_id=4365&file_path=file/path",
             "upload data search file service")
    end

  end

end
