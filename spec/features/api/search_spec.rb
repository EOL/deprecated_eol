require File.dirname(__FILE__) + '/../../spec_helper'

describe 'API:search' do
  before(:all) do
    load_foundation_cache
    @dog_name = 'Dog'
    @domestic_name = "Domestic #{@dog_name}"
    @dog_sci_name = 'Canis lupus familiaris'
    @wolf_name = 'Wolf'
    @wolf_sci_name = 'Canis lupus'
    @wolf = build_taxon_concept(scientific_name: @wolf_sci_name, common_names: [ @wolf_name ], 
                                comments: [], bhl: [], toc: [], sounds: [], images: [], youtube: [], flash: [])
    @dog = build_taxon_concept(scientific_name: @dog_sci_name, common_names: [ @domestic_name ], parent_hierarchy_entry_id: @wolf.hierarchy_entries.first.id,
                               comments: [], bhl: [], toc: [], sounds: [], images: [], youtube: [], flash: [])
    @dog2 = build_taxon_concept(scientific_name: "Canis dog", common_names: [ "doggy" ],
                                comments: [], bhl: [], toc: [], sounds: [], images: [], youtube: [], flash: [])
    SearchSuggestion.gen(taxon_id: @dog.id, term: @dog_name)
    SearchSuggestion.gen(taxon_id: @wolf.id, term: @dog_name)
    EOL::Data.make_all_nested_sets
    EOL::Data.flatten_hierarchies
    EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
  end

  it 'should create an API log including API key' do
    user = User.gen(api_key: User.generate_key)
    check_api_key("/api/search/Canis%20lupus.json?key=#{user.api_key}", user)
  end

  it 'search should do a contains search by default' do
    response = get_as_json("/api/search/Canis%20lupus.json")
    response_object = JSON.parse(source)
    response_object['results'].length.should == 2
  end

  it 'search should do an exact search' do
    response = get_as_json("/api/search/Canis%20lupus.json?exact=1")
    response['results'].length.should == 1
    response['results'][0]['title'].should == @wolf_sci_name

    response = get_as_json("/api/search/Canis.json?exact=1")
    response['results'].length.should == 0
  end

  it 'search should search without a filter and get multiple results' do
    response = get_as_json("/api/search/Dog.json")
    response['results'][0]['title'].should match(/(#{@dog_sci_name}|Canis dog|Canis lupus)/)
    response['results'][1]['title'].should match(/(#{@dog_sci_name}|Canis dog|Canis lupus)/)
    response['results'][2]['title'].should match(/(#{@dog_sci_name}|Canis dog|Canis lupus)/)
    response['results'].length.should == 3
  end

  it 'search should be able to filter by string' do
    response = get_as_json("/api/search/Dog.json?filter_by_string=Canis%20lupus")
    response['results'][0]['title'].should == @dog_sci_name
    response['results'].length.should == 1
  end

  it 'search should be able to filter by taxon_concept_id' do
    response = get_as_json("/api/search/Dog.json?filter_by_taxon_concept_id=#{@wolf.id}")
    response['results'][0]['title'].should == @dog_sci_name
    response['results'].length.should == 1
  end

  it 'search should be able to filter by hierarchy_entry_id' do
    response = get_as_json("/api/search/Dog.json?filter_by_hierarchy_entry_id=#{@wolf.hierarchy_entries.first.id}")
    response['results'][0]['title'].should == @dog_sci_name
    response['results'].length.should == 1
  end

end
