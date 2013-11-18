# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonData do

  before(:all) do
    truncate_all_tables
    drop_all_virtuoso_graphs
    License.create_defaults
    ResourceStatus.create_enumerated
    SpecialCollection.create_defaults
    ContentPartnerStatus.create_enumerated
    @taxon_concept = TaxonConcept.gen
    @user = User.gen
    @prep_string = TaxonData.prepare_search_query(querystring: 'foo')
    @resource = Resource.gen
    @user_added_data = UserAddedData.gen(subject: @taxon_concept)
    @data_point_uri = DataPointUri.gen(taxon_concept_id: @taxon_concept.id)
  end

  before(:each) do
    @mock_row = { data_point_uri: @data_point_uri.uri }
    @taxon_data = TaxonData.new(@taxon_concept, @user)
  end

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

  it 'should create a count query' do
    TaxonData.prepare_search_query(only_count: true, querystring: 'foo').should match(/SELECT COUNT\(\*\) as \?count/)
  end

  it 'should select the list of fields we want' do
    @prep_string.should
      match(/SELECT \?data_point_uri, \?attribute, \?value, \?taxon_concept_id, \?unit_of_measure_uri/)
  end

  it 'should select where some default stuff is expected' do
    [
      "?data_point_uri a <#{DataMeasurement::CLASS_URI}> .",
      "?data_point_uri dwc:occurrenceID ?occurrence_id .",
      "?occurrence_id dwc:taxonID ?taxon_id .",
      "?taxon_id dwc:taxonConceptID ?taxon_concept_id",
      "?data_point_uri dwc:measurementType ?attribute .",
      "?data_point_uri dwc:measurementValue ?value .",
      "?data_point_uri dwc:measurementUnit ?unit_of_measure_uri ."
    ].each do |expectation|
      @prep_string.should match(Regexp.quote(expectation))
    end
  end

  it '#prepare_search_query should filter from and to'
  it '#prepare_search_query should handle numeric query strings'
  it '#prepare_search_query should filter by regex by default'

  it '#get_data should get data from #data' do
    @taxon_data.should_receive(:data).and_return([])
    @taxon_data.get_data
  end

  it 'should populate sources from resources' do
    resource_data_point_uri = DataPointUri.gen(taxon_concept_id: @taxon_concept.id, :resource_id => @resource.id,
      :uri => 'http://resource_data/', :user_added_data_id => nil)
    @mock_row[:data_point_uri] = resource_data_point_uri.uri
    @mock_row[:graph] = "http://eol.org/resources/#{@resource.id}"
    @taxon_data.should_receive(:data).and_return([@mock_row])
    taxon_data_set = @taxon_data.get_data
    taxon_data_set.first.source.should == @resource.content_partner
  end

  it 'should populate sources from user_added_data' do
    user_data_point_uri = DataPointUri.gen(taxon_concept_id: @taxon_concept.id, :user_added_data_id => @user_added_data.id,
      :uri => @user_added_data.uri, :resource_id => nil)
    @mock_row[:data_point_uri] = user_data_point_uri.uri
    @taxon_data.should_receive(:data).and_return([@mock_row])
    taxon_data_set = @taxon_data.get_data
    taxon_data_set.first.source.should == @user_added_data.user
  end

  it 'should add known uris to the rows' do
    KnownUri.should_receive(:add_to_data)
    @taxon_data.get_data
  end

  it 'should preload known_uris'

  it 'should populate categories on #get_data'

  it '#get_data_for_overview should call get_data and use TaxonDataExemplarPicker' do
    picker = TaxonDataExemplarPicker.new(@taxon_data) # Note this is before we add #should_receive.
    TaxonDataExemplarPicker.should_receive(:new).with(@taxon_data).and_return(picker)
    @taxon_data.should_receive(:get_data).and_return('wow')
    picker.should_receive(:pick).with('wow').and_return('back here')
    @taxon_data.get_data_for_overview.should == 'back here'
  end

  it 'should call #get_data if categories are not set' do
    @taxon_data.should_receive(:get_data).and_return(1)
    @taxon_data.categories
  end

end
