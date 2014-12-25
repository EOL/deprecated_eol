require File.dirname(__FILE__) + '/../../spec_helper'

describe 'API:traits' do
  before(:all) do
    load_foundation_cache
    drop_all_virtuoso_graphs
    @taxon_concept = build_taxon_concept(
      hierarchy_entry: HierarchyEntry.gen(rank: Rank.gen_if_not_exists(label: 'species')))
    @hierarchy_entry= @taxon_concept.hierarchy_entries.first
    @target_taxon_concept = build_taxon_concept
    @resource = Resource.gen
    @default_data_options = { subject: @taxon_concept, resource: @resource }
    KnownUri.gen_if_not_exists({ uri: 'http://eol.org/weight', name: 'Weight' })
    KnownUri.gen_if_not_exists({ uri: 'http://eol.org/preys_on', name: 'Preys On' })
    @measurement = DataMeasurement.new(@default_data_options.merge(predicate: 'http://eol.org/weight',
      object: '12345.0', unit: KnownUri.grams.uri))
    @measurement.update_triplestore
    @association = DataAssociation.new(@default_data_options.merge(object: @target_taxon_concept,
      type: 'http://eol.org/preys_on'))
    @association.update_triplestore
  end


  it 'creates an API log including an API key' do
    user = User.gen(api_key: User.generate_key)
    check_api_key("/api/traits/#{@taxon_concept.id}?key=#{user.api_key}", user)
  end

  it 'renders a JSON response' do
    response = get_as_json("/api/traits/1.0/#{@taxon_concept.id}")
    response.class.should == Hash
    expect(response['@context'].length).to eq(14)
    expect(response['@graph'].length).to eq(4)
    expect(response['@graph'][0]['@id']).to eq(KnownUri.taxon_uri(@taxon_concept))
    expect(response['@graph'][0]['dwc:scientificName']).to eq(@taxon_concept.entry.name.string)
    expect(response['@graph'][0]['dwc:taxonRank']).to eq('species')

    expect(response['@graph'][1]['dwc:parentNameUsage']).to eq(@hierarchy_entry.hierarchy.display_title)
    expect(response['@graph'][1]['Synonyms'].length).to eq(2)
    expect(response['@graph'][1]['Synonyms'][0]['dwc:acceptedNameUsage']).to eq(@hierarchy_entry.name.string)
    expect(response['@graph'][1]['Synonyms'][0]['dwc:ResourceRelationship']).to eq(I18n.t(:name_preferred_taxonomically_for_source_yes))
    expect(response['@graph'][1]['Synonyms'][1]['dwc:acceptedNameUsage']).to eq(@hierarchy_entry.scientific_synonyms.first.name.string)
    expect(response['@graph'][1]['Synonyms'][1]['dwc:ResourceRelationship']).to eq(I18n.t(:synonym))
    
    expect(response['@graph'][2]['@id']).to eq(@measurement.uri)
    expect(response['@graph'][2]['@type']).to eq('dwc:MeasurementOrFact')
    expect(response['@graph'][2]['dwc:taxonID']).to eq(KnownUri.taxon_uri(@taxon_concept))
    expect(response['@graph'][2]['dwc:measurementType']['@id']).to eq('http://eol.org/weight')
    expect(response['@graph'][2]['dwc:measurementType']['rdfs:label']['en']).to eq('Weight')
    expect(response['@graph'][2]['dwc:measurementValue']).to eq('12.345') # the value gets converted to kg
    expect(response['@graph'][2]['dwc:measurementUnit']['@id']).to eq(KnownUri.kilograms.uri)
    expect(response['@graph'][2]['dwc:measurementUnit']['rdfs:label']['en']).to eq(KnownUri.kilograms.label)

    expect(response['@graph'][3]['@id']).to eq(@association.uri)
    expect(response['@graph'][3]['@type']).to eq('eol:Association')
    expect(response['@graph'][3]['dwc:taxonID']).to eq(KnownUri.taxon_uri(@taxon_concept))
    expect(response['@graph'][3]['eol:associationType']['@id']).to eq('http://eol.org/preys_on')
    expect(response['@graph'][3]['eol:associationType']['rdfs:label']['en']).to eq('Preys On')
    expect(response['@graph'][3]['eol:targetTaxonID']).to eq(KnownUri.taxon_uri(@target_taxon_concept))
  end

  it 'adds metadata URIs to context' do
    pending
  end
end