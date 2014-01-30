require "spec_helper"

describe ContentUpload do

  before(:all) do
    ContentUpload.delete_all
    CuratorLevel.create_enumerated
    @upload = ContentUpload.gen
  end

  it 'should have a friendly link name with some path stuff on it' do
    @upload.attachment_url.should =~ /\/\w+\/#{@upload.link_name}/
  end

  it 'should downcase the extension' do
    u = ContentUpload.gen(attachment_extension: 'JPG')
    u.ext.should == 'jpg'
  end

  it 'should turn jpeg extensions to jpg' do
    u = ContentUpload.gen(attachment_extension: '.jpeg')
    u.ext.should == '.jpg'
  end

  it 'should delegate #content_server_url to ContentServer#uploaded_content_url' do
    ContentServer.should_receive(:uploaded_content_url).and_return(:yay)
    @upload.content_server_url.should == :yay
  end

end
