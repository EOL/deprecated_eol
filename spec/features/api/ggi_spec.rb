require File.dirname(__FILE__) + '/../../spec_helper'

describe 'API:traits' do
  before(:all) do
    load_foundation_cache
    drop_all_virtuoso_graphs
    images = []
    10.times { images << { :data_rating => 1 + rand(5), :source_url => 'http://photosynth.net/identifying/by/string/is/bad/change/me' } }
    10.times { images << { :data_rating => 1 + rand(5), :vetted => Vetted.unknown } }
    10.times { images << { :data_rating => 1 + rand(5), :vetted => Vetted.untrusted } }
    10.times { images << { :data_rating => 1 + rand(5), :vetted => Vetted.inappropriate } }
    @taxon_concept = build_taxon_concept(:canonical_form => 'Copious picturesqus', :common_names => [ 'Snappy' ],
                                             :images => images, comments: [])
    @resource = Resource.gen
    KnownUri.gen_if_not_exists({ uri: 'http://eol.org/schema/terms/NumberRichSpeciesPagesInEOL', name: 'Rich Pages in EOL' })
    @measurement = DataMeasurement.new(subject: @taxon_concept, resource: @resource,
      predicate: 'http://eol.org/schema/terms/NumberRichSpeciesPagesInEOL', object: '12345')
    @measurement.update_triplestore
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
    @best_image = @taxon_concept.exemplar_or_best_image_from_solr
  end

  # not logging API anymore!
  # it 'should create an API log including API key' do
    # user = User.gen(api_key: User.generate_key)
    # check_api_key("/api/ggi/#{@taxon_concept.id}?key=#{user.api_key}", user)
  # end

  it 'pages should be able to render a JSON response' do
    response = get_as_json("/api/ggi/1.0/#{@taxon_concept.id}")
    response.class.should == Hash
    expect(response['identifier']).to eq(@taxon_concept.id)
    expect(response['scientificName']).to eq(@taxon_concept.entry.name.string)
    expect(response['bestImage']['identifier']).to eq(@best_image.guid)
    expect(response['bestImage']['eolMediaURL']).to eq(DataObject.image_cache_path(
      @best_image.object_cache_url, :orig, :specified_content_host => Rails.configuration.asset_host))

    expect(response['vernacularNames'].length).to eq(1)
    expect(response['vernacularNames'][0]['vernacularName']).to eq('Snappy')
    expect(response['vernacularNames'][0]['language']).to eq('en')
    expect(response['vernacularNames'][0]['eol_preferred']).to eq(true)

    expect(response['measurements'].length).to eq(1)
    expect(response['measurements'][0]['resourceID']).to eq(@resource.id)
    expect(response['measurements'][0]['source']).to eq(@resource.title)
    expect(response['measurements'][0]['measurementType']).to eq('http://eol.org/schema/terms/NumberRichSpeciesPagesInEOL')
    expect(response['measurements'][0]['label']).to eq('Rich Pages in EOL')
    expect(response['measurements'][0]['measurementValue']).to eq(@measurement.object.to_i)
  end
end
