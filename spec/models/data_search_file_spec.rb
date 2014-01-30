require "spec_helper"

def test_and_reset_downloadable
  expect(@search_file.downloadable?).to eq(false)
  @search_file.completed_at = Time.now
  @search_file.row_count = 10
  expect(@search_file.downloadable?).to eq(true)
end

describe DataSearchFile do

  before(:each) do
    @search_file = DataSearchFile.gen
  end

  it 'should upload files' do
    @search_file.hosted_file_url = nil
    ContentServer.should_receive(:upload_data_search_file).with(@search_file.local_file_url, @search_file.id).and_return('download.csv.zip')
    expect(@search_file.hosted_file_url).to eq(nil)
    @search_file.build_file
    expect(@search_file.hosted_file_url).to eq(Rails.configuration.hosted_dataset_path + 'download.csv.zip')
  end

  it 'should know when hosted_file_exists?' do
    @search_file.hosted_file_url = nil
    expect(@search_file.hosted_file_exists?).to eq(false)
    EOLWebService.should_receive('url_accepted?').with('http://works').and_return(true)
    @search_file.hosted_file_url = 'http://works'
    expect(@search_file.hosted_file_exists?).to eq(true)
    EOLWebService.should_receive('url_accepted?').with('http://doesnt').and_return(false)
    @search_file.hosted_file_url = 'http://doesnt'
    expect(@search_file.hosted_file_exists?).to eq(false)
  end

  it 'should known when downloadable?' do
    @search_file.completed_at = nil
    test_and_reset_downloadable
    @search_file.row_count = 0
    test_and_reset_downloadable
    @search_file.row_count = nil
    test_and_reset_downloadable
    @search_file.completed_at = Time.now - DataSearchFile::EXPIRATION_TIME
    test_and_reset_downloadable
  end

  it 'should known when expired?' do
    @search_file.completed_at = Time.now
    expect(@search_file.expired?).to eq(false)
    @search_file.completed_at = Time.now - DataSearchFile::EXPIRATION_TIME
    expect(@search_file.expired?).to eq(true)
  end

end
