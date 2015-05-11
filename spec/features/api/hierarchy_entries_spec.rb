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

   describe "Hierarchy entry descendants" do

    before(:all) do
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
      visit("/api/hierarchy_entries/#{@hierarchy_entry.id}")
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
      visit("/api/hierarchy_entries/#{@hierarchy_entry.id}?render=tcs")
      xml_response = Nokogiri.XML(source)
      expect(xml_response.xpath("//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:TaxonRelationships/xmlns:TaxonRelationship[1]/@type").inner_text).to eq("is ancestor taxon of")
      expect(xml_response.xpath("//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:TaxonRelationships/xmlns:TaxonRelationship[1]/xmlns:ToTaxonConcept/@ref").inner_text).to include("/hierarchy_entries/#{@descentant_hierarchy_entry.id}?render=tcs")
    end

    it 'Should show all information for descendants of hierarchy entries in JSON format' do
      response = get_as_json("/api/hierarchy_entries/#{@hierarchy_entry.id}.json")
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
