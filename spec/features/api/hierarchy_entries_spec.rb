require File.dirname(__FILE__) + '/../../spec_helper'

describe 'API:hierarchy_entries' do
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
  end

  it 'should create an API log including API key' do
    user = User.gen(api_key: User.generate_key)
    check_api_key("/api/hierarchy_entries/#{@hierarchy_entry.id}?key=#{user.api_key}", user)
  end

  it 'hierarchy_entries should show all information for hierarchy entries in DWC format' do
    visit("/api/hierarchy_entries/#{@hierarchy_entry.id}")
    xml_response = Nokogiri.XML(source)
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dc:identifier").inner_text.should == @hierarchy_entry.identifier
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:taxonID").inner_text.should == @hierarchy_entry.id.to_s
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:parentNameUsageID").inner_text.should == @hierarchy_entry.parent_id.to_s
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:taxonConceptID").inner_text.should == @hierarchy_entry.taxon_concept_id.to_s
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:scientificName").inner_text.should == @name.string
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:taxonRank").inner_text.downcase.should == @rank.label
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:nameAccordingTo").inner_text.should == @hierarchy.label
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:vernacularName[1]").inner_text.should == @common_name1.name.string
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:vernacularName[1]/@xml:lang").inner_text.should == @common_name1.language.iso_639_1
    xml_response.xpath("//dwc:vernacularName").length.should == 2
    xml_response.xpath("//dwc:Taxon[dwc:taxonomicStatus='not common name']").length.should == 1
  end

  it 'hierarchy_entries should be able to filter out common names' do
    visit("/api/hierarchy_entries/#{@hierarchy_entry.id}?common_names=0")
    xml_response = Nokogiri.XML(source)
    xml_response.xpath("//dwc:vernacularName").length.should == 0
    xml_response.xpath("//dwc:Taxon[dwc:taxonomicStatus='not common name']").length.should == 1
  end

  it 'hierarchy_entries should be able to filter out synonyms' do
    visit("/api/hierarchy_entries/#{@hierarchy_entry.id}?synonyms=0")
    xml_response = Nokogiri.XML(source)
    xml_response.xpath("//dwc:vernacularName").length.should == 2
    xml_response.xpath("//dwc:Taxon[dwc:taxonomicStatus='not common name']").length.should == 0
  end

  it 'hierarchy_entries should show all information for hierarchy entries in TCS format' do
    visit("/api/hierarchy_entries/#{@hierarchy_entry.id}?render=tcs")
    xml_response = Nokogiri.XML(source)
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/@id').inner_text.should == "n#{@name.id}"
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:Simple').inner_text.should == @name.string
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:CanonicalName/xmlns:Simple').inner_text.should == @canonical_form.string
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:Rank').inner_text.downcase.should == @rank.label
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:Rank/@code').inner_text.should == @rank.tcs_code
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:ProviderSpecificData/xmlns:NameSources/xmlns:NameSource/xmlns:Simple').inner_text.should == @hierarchy.label
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/@id').inner_text.should == "#{@hierarchy_entry.id}"
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name').inner_text.should == "#{@name.string}"
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name/@scientific').inner_text.should == "true"
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name/@ref').inner_text.should == "n#{@name.id}"
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Rank').inner_text.downcase.should == @rank.label
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Rank/@code').inner_text.should == @rank.tcs_code
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:TaxonRelationships/xmlns:TaxonRelationship[1]/xmlns:ToTaxonConcept/@ref').inner_text.should include(@synonym.id.to_s)
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:TaxonRelationships/xmlns:TaxonRelationship[1]/@type').inner_text.should == 'has synonym'
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:TaxonRelationships/xmlns:TaxonRelationship[2]/xmlns:ToTaxonConcept/@ref').inner_text.should include(@common_name1.id.to_s)
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:TaxonRelationships/xmlns:TaxonRelationship[2]/@type').inner_text.should == 'has vernacular'
  end
end
