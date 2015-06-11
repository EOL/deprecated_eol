require File.dirname(__FILE__) + '/../../spec_helper'

describe 'API:hierarchy_entries_descendants' do
  before(:all) do
    load_foundation_cache
    @canonical_form = CanonicalForm.create(string: 'Aus bus')
    @name = Name.create(canonical_form: @canonical_form, string: 'Aus bus Linnaeus 1776')
    @hierarchy = Hierarchy.gen(label: 'Test Hierarchy', browsable: 1, outlink_uri: "outlink")
    @rank = Rank.gen_if_not_exists(label: 'species')
    @hierarchy_entry = HierarchyEntry.gen(identifier: '123abc', hierarchy: @hierarchy, name: @name, published: 1, rank: @rank)

    common_name = SynonymRelation.gen_if_not_exists(label: 'common name')
    @common_name1 = Synonym.gen(hierarchy_entry: @hierarchy_entry, synonym_relation: common_name, language: Language.english)
    @common_name2 = Synonym.gen(hierarchy_entry: @hierarchy_entry, synonym_relation: common_name, language: Language.english)

    not_common_name = SynonymRelation.gen_if_not_exists(label: 'not common name')
    @synonym = Synonym.gen(hierarchy_entry: @hierarchy_entry, synonym_relation: not_common_name)

    @rank_of_descentant_hierarchy_entry = Rank.gen_if_not_exists(label: 'subspecies')
    canonical_form_of_descentant_hierarchy_entry = CanonicalForm.create(string: 'test ')
    @name_of_descentant_hierarchy_entry = Name.create(canonical_form: canonical_form_of_descentant_hierarchy_entry,
                                                     string: 'test string')
    @descentant_hierarchy_entry = HierarchyEntry.gen(identifier: '123abb', hierarchy: @hierarchy,
                                                    name: @name_of_descentant_hierarchy_entry, published: 1,
                                                    rank: @rank_of_descentant_hierarchy_entry)
    HierarchyEntriesFlattened.create(hierarchy_entry_id: @descentant_hierarchy_entry.id , ancestor_id: @hierarchy_entry.id)
  end


  it 'Should show all information for descendants of hierarchy entries in DWC format' do
    visit("/api/hierarchy_entries_descendants/#{@hierarchy_entry.id}")
    xml_response = Nokogiri.XML(source)
    expect(xml_response.xpath("//dwc:Descendants")).not_to be_nil
    expect(xml_response.xpath("//dwc:Descendants//dwc:Taxon//dc:identifier").inner_text).to eq(@descentant_hierarchy_entry.identifier)
    expect(xml_response.xpath("//dwc:Descendants//dwc:Taxon//dwc:taxonID").inner_text).to eq(@descentant_hierarchy_entry.id.to_s)
    expect(xml_response.xpath("//dwc:Descendants//dwc:Taxon//dwc:parentNameUsageID").inner_text).to eq(@descentant_hierarchy_entry.parent_id.to_s)
    expect(xml_response.xpath("//dwc:Descendants//dwc:Taxon//dwc:taxonConceptID").inner_text).to eq(@descentant_hierarchy_entry.taxon_concept_id.to_s)
    expect(xml_response.xpath("//dwc:Descendants//dwc:Taxon//dwc:scientificName").inner_text).to eq(@name_of_descentant_hierarchy_entry.string)
    expect(xml_response.xpath("//dwc:Descendants//dwc:Taxon//dwc:taxonRank").inner_text).to eq(@rank_of_descentant_hierarchy_entry.label)
    expect(xml_response.xpath("//dwc:Descendants//dwc:Taxon//dc:source").inner_text).to eq(@hierarchy.outlink_uri)
  end

  it 'Should show all information for descendants of hierarchy entries in TCS format' do
    visit("/api/hierarchy_entries_descendants/#{@hierarchy_entry.id}?render=tcs")
    xml_response = Nokogiri.XML(source)
    expect(xml_response.xpath("//xmlns:TaxonConcepts/xmlns:TaxonRelationships/xmlns:TaxonRelationship[1]/@type").inner_text).to eq("is ancestor taxon of")
    expect(xml_response.xpath("//xmlns:TaxonConcepts/xmlns:TaxonRelationships/xmlns:TaxonRelationship[1]/xmlns:ToTaxonConcept/@ref").inner_text).to include("/hierarchy_entries/#{@descentant_hierarchy_entry.id}?render=tcs")
  end

  it 'Should show all information for descendants of hierarchy entries in JSON format' do
    response = get_as_json("/api/hierarchy_entries_descendants/#{@hierarchy_entry.id}.json")
    expect(response["descendants"]).not_to be_nil
    expect(response["descendants"][0]["sourceIdentifier"]).to eq(@descentant_hierarchy_entry.identifier.to_s)
    expect(response["descendants"][0]["taxonID"]).to eq(@descentant_hierarchy_entry.id)
    expect(response["descendants"][0]["parentNameUsageID"]).to  eq(@descentant_hierarchy_entry.parent_id)
    expect(response["descendants"][0]["taxonConceptID"]).to eq(@descentant_hierarchy_entry.taxon_concept_id)
    expect(response["descendants"][0]["scientificName"]).to eq(@name_of_descentant_hierarchy_entry.string)
    expect(response["descendants"][0]["taxonRank"]).to eq(@rank_of_descentant_hierarchy_entry.label)
    expect(response["descendants"][0]["source"]).to eq(@hierarchy.outlink_uri)
  end
end
