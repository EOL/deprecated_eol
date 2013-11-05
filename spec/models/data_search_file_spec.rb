require 'spec_helper'

describe DataSearchFile do

  before(:each) do
    @search_file = DataSearchFile.gen
  end

  it 'should upload files' do
    @search_file = DataSearchFile.gen
    @search_file.hosted_file_url.should == nil
    ContentServer.should_receive(:upload_data_search_file).with(@search_file.local_file_url, @search_file.id).and_return('download.csv.zip')
    @search_file.build_file
    @search_file.hosted_file_url.should == Rails.configuration.hosted_dataset_path + 'download.csv.zip'
  end

end
