require File.dirname(__FILE__) + '/../../../spec_helper'

describe EOL::Sparql::SearchQueryBuilder do
  before(:all) do
    load_foundation_cache
    @taxon_concept = build_taxon_concept(:comments => [], :bhl => [], :toc => [], :images => [], :sounds => [], :youtube => [], :flash => [])
  end

  describe '#initialize' do
    it 'should initialize from an array' do
      expect(EOL::Sparql::SearchQueryBuilder.new(page: 123).instance_variable_get('@page')).to eq(123)
      expect(EOL::Sparql::SearchQueryBuilder.new(per_page: 987).instance_variable_get('@per_page')).to eq(987)
    end

    it 'should set default paging values' do
      expect(EOL::Sparql::SearchQueryBuilder.new({}).instance_variable_get('@page')).to eq(1)
      expect(EOL::Sparql::SearchQueryBuilder.new({}).instance_variable_get('@per_page')).to eq(TaxonData::DEFAULT_PAGE_SIZE)
    end
  end

  describe '#build_query' do
    it 'should assemble queries' do
      expect(EOL::Sparql::SearchQueryBuilder.build_query('SEL', 'WHE', 'ORD', 'LIM')).
        to match(/SEL WHERE {\s*WHE\s*}\s*ORD\s*LIM/)
    end
  end

  describe '#prepare_search_query' do
    it 'creates a count query' do
      expect(EOL::Sparql::SearchQueryBuilder.prepare_search_query(only_count: true,
        querystring: 'foo')).to include('SELECT COUNT(*) as ?count')
    end

    it 'selects the list of fields we want' do
      expect(EOL::Sparql::SearchQueryBuilder.prepare_search_query(querystring:
        'foo')).to include('SELECT DISTINCT ?attribute ?value ?unit_of_measure_uri '+
                           '?statistical_method ?life_stage ?sex ?data_point_uri ?graph ?taxon_concept_id')
    end

    it 'searches with expected conditions' do
      [ "?data_point_uri dwc:occurrenceID ?occurrence_id .",
        "?occurrence_id dwc:taxonID ?taxon_id .",
        "?taxon_id dwc:taxonConceptID ?taxon_concept_id",
        "?data_point_uri dwc:measurementType ?attribute .",
        "?data_point_uri dwc:measurementValue ?value .",
        "OPTIONAL { ?data_point_uri dwc:measurementUnit ?unit_of_measure_uri } ."
      ].each do |expectation|
        expect(EOL::Sparql::SearchQueryBuilder.prepare_search_query(querystring: 'foo')).
          to include(expectation)
      end
    end

    it 'filters on taxon' do
      [ "?parent_taxon dwc:taxonConceptID <http://eol.org/pages/#{@taxon_concept.id}> .",
        "?parent_taxon dwc:taxonConceptID ?parent_taxon_concept_id .",
        "?t dwc:parentNameUsageID+ ?parent_taxon .",
        "?t dwc:taxonConceptID ?taxon_concept_id"
      ].each do |expectation|
        expect(EOL::Sparql::SearchQueryBuilder.prepare_search_query(querystring: 'foo',
          taxon_concept: @taxon_concept)).to include(expectation)
      end
    end

    it 'counts occurrences of values' do
      expect(EOL::Sparql::SearchQueryBuilder.prepare_search_query(count_value_uris: true,
        querystring: 'foo')).to include('SELECT ?value, COUNT(*) as ?count WHERE')
    end

    it 'sorts ascending' do
      expect(EOL::Sparql::SearchQueryBuilder.prepare_search_query(querystring: 'foo',
        sort: 'asc')).to include('ORDER BY ASC(xsd:float(?value)) ASC(?value)')
    end

    it 'sorts descending' do
      expect(EOL::Sparql::SearchQueryBuilder.prepare_search_query(querystring: 'foo',
        sort: 'desc')).to include('ORDER BY DESC(xsd:float(?value)) DESC(?value)')
    end

    it 'filters on min value' do
      expect(EOL::Sparql::SearchQueryBuilder.prepare_search_query(querystring: 'foo',
        min_value: 10)).to include('FILTER(xsd:float(?value) >= xsd:float(10)) .')
    end

    it 'filters on max value' do
      expect(EOL::Sparql::SearchQueryBuilder.prepare_search_query(querystring: 'foo',
        max_value: 20)).to include('FILTER(xsd:float(?value) <= xsd:float(20)) .')
    end

    it 'filters on exact numeric values' do
      expect(EOL::Sparql::SearchQueryBuilder.prepare_search_query(querystring: '30')).
        to include('FILTER(xsd:float(?value) = xsd:float(30)) .')
    end

    it 'filters on known uris' do
      k = KnownUri.gen_if_not_exists(uri: "http://filter", name: 'filter')
      expect(EOL::Sparql::SearchQueryBuilder.prepare_search_query(querystring: k.label)).
        to include("|| ?value IN (<#{k.uri}>)")
    end

    it 'filters on units' do
      expect(EOL::Sparql::SearchQueryBuilder.prepare_search_query(min_value: 30,
        unit: KnownUri.grams.uri)).to include("FILTER((?unit_of_measure_uri IN (<#{KnownUri.grams.uri}>")
    end
  end

  # it '#prepare_search_query should filter by regex by default'
  # it 'should not search clades that are too large'

end
