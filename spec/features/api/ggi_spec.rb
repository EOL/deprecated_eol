require File.dirname(__FILE__) + '/../../spec_helper'

describe 'API:traits' do
  before(:all) do
    truncate_all_tables
    drop_all_virtuoso_graphs
    load_scenario_with_caching :media_heavy
    @data = EOL::TestInfo.load('media_heavy')
    @taxon_concept = @data[:taxon_concept]
    @resource = Resource.gen
    KnownUri.gen_if_not_exists({ uri: TripleStore::GGI_URIS.first, name: 'Rich Pages in EOL' })
    @measurement = DataMeasurement.new(subject: @taxon_concept, resource: @resource,
      predicate: TripleStore::GGI_URIS.first, object: '12345')
    @measurement.update_triplestore
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
    @best_image = @taxon_concept.exemplar_or_best_image_from_solr
  end

  it 'should create an API log including API key' do
    user = User.gen(api_key: User.generate_key)
    check_api_key("/api/ggi/#{@taxon_concept.id}?key=#{user.api_key}", user)
  end

  it 'pages should be able to render a JSON response' do
    response = get_as_json("/api/ggi/1.0/#{@taxon_concept.id}")
    response.class.should == Hash
    expect(response['identifier']).to eq(@taxon_concept.id)
    expect(response['scientificName']).to eq(@taxon_concept.entry.name.string)
    expect(response['bestImage']['identifier']).to eq(@best_image.guid)
    expect(response['bestImage']['eolMediaURL']).to eq(DataObject.image_cache_path(
      @best_image.object_cache_url, :orig, :specified_content_host => $SINGLE_DOMAIN_CONTENT_SERVER))

    expect(response['vernacularNames'].length).to eq(1)
    expect(response['vernacularNames'][0]['vernacularName']).to eq('Snappy')
    expect(response['vernacularNames'][0]['language']).to eq('en')
    expect(response['vernacularNames'][0]['eol_preferred']).to eq(true)

    expect(response['measurements'].length).to eq(1)
    expect(response['measurements'][0]['resourceID']).to eq(@resource.id)
    expect(response['measurements'][0]['source']).to eq(@resource.title)
    expect(response['measurements'][0]['measurementType']).to eq(TripleStore::GGI_URIS.first)
    expect(response['measurements'][0]['label']).to eq('Rich Pages in EOL')
    expect(response['measurements'][0]['measurementValue']).to eq(@measurement.object.to_i)
  end
end
