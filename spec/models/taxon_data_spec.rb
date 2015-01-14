# encoding: utf-8
require "spec_helper"

describe TaxonData do

  before(:all) do
    truncate_all_tables
    drop_all_virtuoso_graphs
    License.create_enumerated
    ResourceStatus.create_enumerated
    SpecialCollection.create_enumerated
    ContentPartnerStatus.create_enumerated
    Permission.create_enumerated
    @taxon_concept = TaxonConcept.gen
    @user = User.gen
    @user.grant_permission(:see_data)
    @prep_string = EOL::Sparql::SearchQueryBuilder.prepare_search_query(querystring: 'foo')
    @resource = Resource.gen
    @user_added_data = UserAddedData.gen(subject: @taxon_concept)
    @data_point_uri = DataPointUri.gen(taxon_concept_id: @taxon_concept.id)
    @test_pred = "http://purl.obolibrary.org/obo/UO_0000016"
    @test_pred_ranges = "http://purl.obolibrary.org/obo/UO_0000009"
    @kilogram_uri = "http://purl.obolibrary.org/obo/UO_0000009"    
    load_scenario_with_caching(:testy)       
  end

  let(:mock_row) { { data_point_uri: @data_point_uri.uri } }
  let(:taxon_data) { TaxonData.new(@taxon_concept, @user) }

  it 'should NOT run any queries on blank search' do
    EOL::Sparql.connection.should_not_receive(:query)
    TaxonData.search(querystring: '').should == []
  end

  it 'should run queries on search and paginate results' do
    foo = EOL::Sparql::VirtuosoClient.new
    EOL::Sparql.should_receive(:connection).at_least(2).times.and_return(foo)
    foo.should_receive(:query).at_least(2).times.and_return([])
    WillPaginate::Collection.should_receive(:create).and_return([])
    foo = TaxonData.search(querystring: 'whatever', attribute: 'anything')
  end

  it '#get_data should get data from #raw_data' do
    taxon_data.should_receive(:raw_data).and_return([])
    taxon_data.get_data
  end

  it '#is_clade_searchable? should know if clade is searchable'

  it 'should populate sources from resources' do
    resource_data_point_uri = DataPointUri.gen(taxon_concept_id: @taxon_concept.id, resource_id: @resource.id,
      uri: 'http://resource_data/', user_added_data_id: nil)
    mock_row[:data_point_uri] = resource_data_point_uri.uri
    mock_row[:graph] = "http://eol.org/resources/#{@resource.id}"
    taxon_data.should_receive(:raw_data).and_return([mock_row])
    taxon_data_set = taxon_data.get_data
    taxon_data_set.first.source.should == @resource.content_partner
  end

  it 'should populate sources from user_added_data' do
    user_data_point_uri = DataPointUri.gen(taxon_concept_id: @taxon_concept.id, user_added_data_id: @user_added_data.id,
      uri: @user_added_data.uri, resource_id: nil)
    mock_row[:data_point_uri] = user_data_point_uri.uri
    taxon_data.should_receive(:raw_data).and_return([mock_row])
    taxon_data_set = taxon_data.get_data
    taxon_data_set.first.source.should == @user_added_data.user
  end

  it 'should add known uris to the rows' do
    KnownUri.should_receive(:add_to_data)
    taxon_data.get_data
  end

  it 'should preload known_uris'

  it 'should populate categories on #get_data'

  it 'should return nil if the user cannot see data' do
    user = User.gen
    user.revoke_permission(:see_data) # Shouldn't have it, but just in case.
    hidden_taxon_data = TaxonData.new(@taxon_concept, user)
    expect(hidden_taxon_data.get_data_for_overview).to be_nil
  end

  it '#get_data_for_overview should use TaxonDataExemplarPicker' do
    picker = TaxonDataExemplarPicker.new(taxon_data) # Note this is before we add #should_receive.
    TaxonDataExemplarPicker.should_receive(:new).with(taxon_data).and_return(picker)
    picker.should_receive(:pick).and_return('back here')
    taxon_data.get_data_for_overview.should == 'back here'
  end

  it 'should call #get_data if categories are not set' do
    taxon_data.should_receive(:get_data).and_return(1)
    taxon_data.categories
  end
  
  it 'should return the entered data with the normalized units' do
    search_options = {querystring: "", attribute: @test_pred, min_value: nil, max_value: nil, unit: nil, sort: "desc",       
      taxon_concept: nil, page: 1, per_page: 30}
    instance = DataMeasurement.new(predicate: @test_pred, object: "100", resource: @resource, subject: @taxon_concept, normalized_value: "10000")
    instance.add_to_triplestore
    instance = DataMeasurement.new(predicate: @test_pred, object: "10", resource: @resource, subject: @taxon_concept, normalized_value: "1000")
    instance.add_to_triplestore
    TaxonData.search(search_options).length.should == 2
  end
  
  it 'shouldnot return values without the normalized units' do  
    search_options = {querystring: "", attribute: @test_pred, min_value: nil, max_value: nil, unit: nil, sort: "desc",       
      taxon_concept: nil, page: 1, per_page: 30}    
    len = TaxonData.search(search_options).length  
    instance = DataMeasurement.new(predicate: @test_pred, object: "100", resource: @resource, subject: @taxon_concept)
    instance.add_to_triplestore
    instance = DataMeasurement.new(predicate: @test_pred, object: "10", resource: @resource, subject: @taxon_concept)
    instance.add_to_triplestore
    TaxonData.search(search_options).length.should == len
  end
  
  it 'should have range if they are entered with same predicate with different values' do
    tc = build_taxon_concept(hierarchy_entry: HierarchyEntry.gen(rank_id: '0'))
    tc.should_receive(:number_of_descendants).and_return(100)    
    instance = DataMeasurement.new(predicate: @test_pred_ranges, object: "10", resource: @resource, subject: tc, normalized_value: "10", 
      normalized_unit: @kilogram_uri, unit: @kilogram_uri)
    instance.add_to_triplestore
    instance = DataMeasurement.new(predicate: @test_pred_ranges, object: "100", resource: @resource, subject: tc, normalized_value: "100", 
      normalized_unit: @kilogram_uri, unit: @kilogram_uri)
    instance.add_to_triplestore
    taxon_data_new = TaxonData.new(tc)
    taxon_data_new.has_range_data.should == true
  end
  
  it 'should show min value in the range' do
    tc = build_taxon_concept(hierarchy_entry: HierarchyEntry.gen(rank_id: '0'))
    tc.should_receive(:number_of_descendants).and_return(100)    
    instance = DataMeasurement.new(predicate: @test_pred_ranges, object: "10", resource: @resource, subject: tc, normalized_value: "10", 
      normalized_unit: @kilogram_uri, unit: @kilogram_uri)
    instance.add_to_triplestore
    instance = DataMeasurement.new(predicate: @test_pred_ranges, object: "100", resource: @resource, subject: tc, normalized_value: "100", 
      normalized_unit: @kilogram_uri, unit: @kilogram_uri)
    instance.add_to_triplestore
    taxon_data_new = TaxonData.new(tc)
    taxon_data_new.ranges_of_values[0][:min].object.should == 10.0
  end

  it 'should show max value in the range' do
    tc = build_taxon_concept(hierarchy_entry: HierarchyEntry.gen(rank_id: '0'))
    tc.should_receive(:number_of_descendants).and_return(100)    
    instance = DataMeasurement.new(predicate: @test_pred_ranges, object: "10", resource: @resource, subject: tc, normalized_value: "10", 
      normalized_unit: @kilogram_uri, unit: @kilogram_uri)
    instance.add_to_triplestore
    instance = DataMeasurement.new(predicate: @test_pred_ranges, object: "100", resource: @resource, subject: tc, normalized_value: "100", 
      normalized_unit: @kilogram_uri, unit: @kilogram_uri)
    instance.add_to_triplestore
    taxon_data_new = TaxonData.new(tc)
    taxon_data_new.ranges_of_values[0][:max].object.should == 100.0
  end
end
