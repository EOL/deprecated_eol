require 'spec_helper'

describe DataSearchFile do

  it 'should upload files' do
    d = DataSearchFile.gen
    d.hosted_file_url.should == nil
    ContentServer.should_receive(:upload_data_search_file).with(d.local_file_url, d.id).and_return('download.csv.zip')
    d.build_file
    d.hosted_file_url.should == $HOSTED_DATASET_PATH + 'download.csv.zip'
  end

end
