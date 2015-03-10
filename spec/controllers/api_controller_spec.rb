require "spec_helper"

describe ApiController do
  before(:all) do
    load_foundation_cache
    # create some entry in the default hierarchy with an identifier - needed to render some API docs
    build_hierarchy_entry(0, TaxonConcept.gen, Name.gen, :identifier => 12345, :hierarchy => Hierarchy.default)
    begin
      @taxon_concept = build_taxon_concept(:comments => [], :images => [], :flash => [], :youtube => [], :sounds => [], :bhl => [])
    rescue ActiveRecord::RecordInvalid => invalid
      puts invalid.record.errors
      puts "So, not sure what causes that; can you look into it?"
    end
  end

  it 'there should be at least 9 API methods' do
    # [ :ping, :pages, :search, :collections, :data_objects, :hierarchy_entries, :hierarchies, :provider_hierarchies, :search_by_provider ]
    EOL::Api::METHODS.length.should >= 9
  end

  it 'should load the class corresponding to each API method' do
    EOL::Api::METHODS.each do |method_name|
      latest_version_method = EOL::Api.default_version_of(method_name)
      # load the documentation page: e.g. api/docs/search
      get method_name
      assigns[:api_method].should == latest_version_method
    end
  end

  it 'should set cache headers' do
    get :pages, :id => @taxon_concept.id, :cache_ttl => 100
    response.header['Cache-Control'].should == 'max-age=100, public'
    get :pages, :id => @taxon_concept.id, :cache_ttl => 200
    response.header['Cache-Control'].should == 'max-age=200, public'
    get :pages, :id => @taxon_concept.id, :cache_ttl => 3600
    response.header['Cache-Control'].should == 'max-age=3600, public'
  end

  it 'should only cache responses when requested' do
    get :pages, :id => @taxon_concept.id
    response.header['Cache-Control'].should == nil
    get :pages, :id => @taxon_concept.id, :cache_ttl => 100
    response.header['Cache-Control'].should == 'max-age=100, public'
    get :pages, :id => @taxon_concept.id
    response.header['Cache-Control'].should == nil
  end

  it 'should not add cache headers when there is an error' do
    get :pages, :id => 1234567890
    response.status.should == 404
    response.header['Cache-Control'].should == nil
    get :pages, :id => 1234567890, :cache_ttl => 100
    response.header['Cache-Control'].should == nil
    get :pages, :id => 1234567890
    response.header['Cache-Control'].should == nil
  end

  it 'should generate 404 errors for missing or unpublished records' do
    get :pages, :id => @taxon_concept.id
    response.status.should == 200
    get :pages, :id => 1234567890
    response.status.should == 404
    get :data_objects, :id => @taxon_concept.data_objects.first.id
    response.status.should == 200
    get :data_objects, :id => 1234567890
    response.status.should == 404
  end
end
