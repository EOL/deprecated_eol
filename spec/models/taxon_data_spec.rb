# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonData do

  before(:all) do
    SpecialCollection.create_all
    @taxon_concept = TaxonConcept.gen
    @user = User.gen
    @prep_string = TaxonData.prepare_search_query(querystring: 'foo')
    @data_point_uri = DataPointUri.gen(taxon_concept_id: @taxon_concept.id)
    @resource = Resource.gen
    @user_added_data = UserAddedData.gen(subject: @taxon_concept)
  end

  before(:each) do
    @mock_row = {data_point_uri: @data_point_uri}
    @taxon_data = TaxonData.new(@taxon_concept, @user)
  end

  it 'should NOT run any queries on blank search' do
    EOL::Sparql.connection.should_not_receive(:query)
    TaxonData.search(querystring: '').should be_nil
  end

  it 'should run queries on search and paginate results' do
    foo = EOL::Sparql::VirtuosoClient.new
    EOL::Sparql.should_receive(:connection).at_least(2).times.and_return(foo)
    foo.should_receive(:query).at_least(2).times.and_return([])
    WillPaginate::Collection.should_receive(:create).and_return([])
    foo = TaxonData.search(querystring: 'whatever')
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
      "?data_point_uri dwc:taxonID ?taxon_id .",
      "?taxon_id dwc:taxonConceptID ?taxon_concept_id .",
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

  it 'should add data to the row for user-added data' do
    @taxon_data.should_receive(:data).and_return([@mock_row])
    UserAddedData.should_receive(:from_value).and_return(@user_added_data)
    user = User.gen
    @user_added_data.should_receive(:user).and_return(user)
    @taxon_data.get_data
    @mock_row[:user].should == user
    @mock_row[:source].should == user
    @mock_row[:user_added_data].should == @user_added_data
  end

  it 'should add a resource id to rows if graphed' do
    @taxon_data.should_receive(:data).and_return([@mock_row])
    @mock_row[:graph] = 'blah/blah/graph/hiya'
    @taxon_data.get_data
    @mock_row[:resource_id].should == 'hiya'
  end

  it 'should populate sources from resources' do
    @mock_row[:resource_id] = @resource.id
    @taxon_data.should_receive(:data).and_return([@mock_row])
    @taxon_data.get_data
    @mock_row[:source].should == @resource.content_partner
  end

  it 'should add known uris to the rows' do
    KnownUri.should_receive(:add_to_data)
    @taxon_data.get_data
  end

  it 'should replace taxon concept uris' do
    KnownUri.should_receive(:replace_taxon_concept_uris)
    @taxon_data.get_data
  end

  it 'should preload taxon concepts' do
    TaxonData.should_receive(:preload_target_taxon_concepts)
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
