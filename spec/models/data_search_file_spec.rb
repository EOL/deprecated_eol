require "spec_helper"

describe DataSearchFile do

  def test_and_reset_downloadable
    expect(@search_file.downloadable?).to eq(false)
    @search_file.completed_at = Time.now
    @search_file.row_count = 10
    @search_file.hosted_file_url = "something"
    expect(@search_file.downloadable?).to eq(true)
  end

  def make_and_convert(options)
    d = DataPointUri.new(options, taxon_concept: TaxonConcept.gen)
    d.convert_units
    d
  end

  before(:all) do
    load_foundation_cache
  end

  before(:each) do
    @search_file = DataSearchFile.gen
  end

  it 'should upload files' do
    @search_file.hosted_file_url = nil
    ContentServer.should_receive(:upload_data_search_file).with(@search_file.local_file_url, @search_file.id).and_return({response:'download.csv.zip', error: nil})
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

  it 'should know when downloadable?' do
    @search_file.completed_at = nil
    test_and_reset_downloadable
    @search_file.row_count = 0
    test_and_reset_downloadable
    @search_file.row_count = nil
    test_and_reset_downloadable
    @search_file.completed_at = 1.minute.ago - DataSearchFile::EXPIRATION_TIME
    test_and_reset_downloadable
  end

  it 'should know when expired?' do
    @search_file.completed_at = Time.now
    expect(@search_file.expired?).to eq(false)
    @search_file.completed_at = 1.minute.ago - DataSearchFile::EXPIRATION_TIME
    expect(@search_file.expired?).to eq(true)
  end

  it 'removes hidden rows' do
    uris = []
    uris << DataPointUri.gen
    uris << DataPointUri.gen
    uris << DataPointUri.gen
    uris << DataPointUri.gen(visibility: Visibility.invisible)
    expect(uris.last.hidden?).to be_true # Just a sanity check; this isn't really needed.
    uris.should_receive(:total_entries).and_return(4)
    names = uris.map { |n| n.source.name } # The uris array WILL BE MODIFIED, so we can't test off of it directly.
    TaxonData.should_receive(:search).and_return(uris)
    csv = @search_file.csv
    expect(csv).to match(names.first)
    expect(csv).to match(names.second)
    expect(csv).to match(names.third)
    expect(csv).to_not include(names.last)
  end

  it 'handles converted units' do
    uris = [ make_and_convert(object: 1000, unit_of_measure_known_uri: KnownUri.milligrams) ]
    uris.should_receive(:total_entries).and_return(1)
    TaxonData.should_receive(:search).and_return(uris)
    csv = @search_file.csv
    expect(csv).to include("1.0")
    expect(csv).to include("grams")
    expect(csv).to include("1000")
    expect(csv).to include("milligrams")
  end

  it 'maintains original unit even when not converted' do
    uris = [ make_and_convert(object: 500, unit_of_measure_known_uri: KnownUri.milligrams) ]
    uris.should_receive(:total_entries).and_return(1)
    TaxonData.should_receive(:search).and_return(uris)
    csv = @search_file.csv
    # there are two places to see units - converted and original value columns
    expect(csv).to match(/(500.*milligrams.*){2}/)
  end

end
