require "spec_helper"

describe InaturalistProjectInfo do

  before(:all) do
    @inat_collection_url = Rails.configuration.inat_collection_url
    @empty_response = "[]"
    @bad_response = "This is not JSON"
  end

  before(:each) do
    Rails.configuration.inat_collection_url = "http://foo.bar"
    $TESTING_INATURALIST_PROJECTS = true
    InaturalistProjectInfo.unlock_caching
    InaturalistProjectInfo.clear_cache
  end

  after(:each) do
    $TESTING_INATURALIST_PROJECTS = false
    Rails.configuration.inat_collection_url = @inat_collection_url
  end

  it 'should get info on a project from the cache' do
    Rails.cache.write(InaturalistProjectInfo.cache_key, {1234 => 'foobar'})
    InaturalistProjectInfo.get(1234).should == 'foobar'
  end

  it 'should get info on a project from iNat if not cached' do
    Net::HTTP.should_receive(:get).and_return('[{"source_url":"eol.org/collections/1234","foo":"bar"}]')
    InaturalistProjectInfo.get(1234)['foo'].should == 'bar'
  end

  it 'should NOT get info on a project if we have already created the cache' do
    Rails.cache.write(InaturalistProjectInfo.cache_key, {})
    Net::HTTP.should_not_receive(:get)
    InaturalistProjectInfo.get(1234)['foo']
  end

  it 'should log a warning and return nil if something goes wrong getting iNat info' do
    Rails.logger.should_receive(:warn)
    Net::HTTP.should_receive(:get).and_return(@bad_response)
    InaturalistProjectInfo.get(1234).should be_nil
  end

  it 'should NOT want to cache if already cached' do
    Rails.cache.write(InaturalistProjectInfo.cache_key, true)
    InaturalistProjectInfo.needs_caching?.should_not be_true
  end

  it 'should NOT want to cache if locked' do
    InaturalistProjectInfo.lock_caching
    InaturalistProjectInfo.needs_caching?.should_not be_true
  end

  it 'should want to cache if nothing is cached' do
    InaturalistProjectInfo.needs_caching?.should be_true
  end

  it '#cache_all should get all pages from iNat' do # Note, this is not a great test. :\
    Net::HTTP.should_receive(:get).and_return(@empty_response)
    InaturalistProjectInfo.cache_all
  end

  it '#cache_all should lock caching' do
    Net::HTTP.should_receive(:get).and_return(@empty_response)
    InaturalistProjectInfo.should_receive(:lock_caching)
    InaturalistProjectInfo.cache_all
  end

  it '#cache_all should unlock caching' do
    Net::HTTP.should_receive(:get).and_return(@empty_response)
    InaturalistProjectInfo.should_receive(:unlock_caching)
    InaturalistProjectInfo.cache_all
  end

  it '#cache_all should unlock caching even if it fails' do
    Net::HTTP.should_receive(:get).and_return(@bad_response)
    InaturalistProjectInfo.should_receive(:unlock_caching)
    InaturalistProjectInfo.cache_all
  end

end
