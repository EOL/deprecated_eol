require File.dirname(__FILE__) + '/../../spec_helper'

describe EOL::Sparql::SearchQueryBuilder do

  it 'should initialize from an array' do
    expect(EOL::Sparql::SearchQueryBuilder.new(page: 123).instance_variable_get('@page')).to eq(123)
    expect(EOL::Sparql::SearchQueryBuilder.new(per_page: 987).instance_variable_get('@per_page')).to eq(987)
  end

  it 'should set default paging values' do
    expect(EOL::Sparql::SearchQueryBuilder.new({}).instance_variable_get('@page')).to eq(1)
    expect(EOL::Sparql::SearchQueryBuilder.new({}).instance_variable_get('@per_page')).to eq(TaxonData::DEFAULT_PAGE_SIZE)
  end

  it 'should assemble queries' do
    EOL::Sparql::SearchQueryBuilder.build_query('SEL', 'WHE', 'ORD', 'LIM').should match(/SEL WHERE {\s*WHE\s*}\s*ORD\s*LIM/)
  end

  it 'should create a count query' do
    EOL::Sparql::SearchQueryBuilder.prepare_search_query(only_count: true, querystring: 'foo').should match(/SELECT COUNT\(\*\) as \?count/)
  end

  it 'should select the list of fields we want' do
    EOL::Sparql::SearchQueryBuilder.prepare_search_query(querystring: 'foo').should
      match(/SELECT \?data_point_uri, \?attribute, \?value, \?taxon_concept_id, \?unit_of_measure_uri, \?statistical_method, \?life_stage, \?sex/)
  end

  it 'should select where some default stuff is expected' do
    [
      "?data_point_uri dwc:occurrenceID ?occurrence_id .",
      "?occurrence_id dwc:taxonID ?taxon_id .",
      "?taxon_id dwc:taxonConceptID ?taxon_concept_id",
      "?data_point_uri dwc:measurementType ?attribute .",
      "?data_point_uri dwc:measurementValue ?value .",
      "OPTIONAL { ?data_point_uri dwc:measurementUnit ?unit_of_measure_uri } ."
    ].each do |expectation|
      EOL::Sparql::SearchQueryBuilder.prepare_search_query(querystring: 'foo').should match(Regexp.quote(expectation))
    end
  end

  # it '#prepare_search_query should filter from and to'
  # it '#prepare_search_query should handle numeric query strings'
  # it '#prepare_search_query should filter by regex by default'
  # it 'should not search clades that are too large'

end
