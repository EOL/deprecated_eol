require File.dirname(__FILE__) + '/../../spec_helper'

describe 'API:synonyms' do
  before(:all) do
    load_foundation_cache
    hierarchy_entry = HierarchyEntry.gen
    name = Name.create(string: 'Some critter')
    relation = SynonymRelation.gen_if_not_exists(label: 'common name')
    language = Language.gen_if_not_exists(label: 'english', iso_639_1: 'en')
    @common_name1 = Synonym.gen(hierarchy_entry: hierarchy_entry, name: name, synonym_relation: relation, language: language)

    canonical_form = CanonicalForm.create(string: 'Dus bus')
    name = Name.create(canonical_form: @canonical_form, string: 'Dus bus Linnaeus 1776')
    relation = SynonymRelation.gen_if_not_exists(label: 'not common name')
    @synonym = Synonym.gen(hierarchy_entry: hierarchy_entry, name: name, synonym_relation: relation)
  end

  # not logging API anymore!
  # it 'should create an API log including API key' do
    # user = User.gen(api_key: User.generate_key)
    # check_api_key("/api/synonyms/#{@synonym.id}?key=#{user.api_key}", user)
  # end

  it 'synonyms should show all information for synonyms in TCS format' do
    response = get_as_xml("/api/synonyms/#{@synonym.id}")
    response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/@id').inner_text.should == "n#{@synonym.name.id}"
    response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:Simple').inner_text.should == @synonym.name.string
    response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:CanonicalName/xmlns:Simple').inner_text.should ==
      @synonym.name.canonical_form.string
    response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/@id').inner_text.should == "s#{@synonym.id}"
    response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name').inner_text.should == "#{@synonym.name.string}"
    response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name/@scientific').inner_text.should == "true"
  end

  it 'synonyms should show all information for common names in TCS format' do
    response = get_as_xml("/api/synonyms/#{@common_name1.id}")
    response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/@id').inner_text.should == "n#{@common_name1.name.id}"
    response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:Simple').inner_text.should == @common_name1.name.string
    # canonical form not included for common names
    response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:CanonicalName/xmlns:Simple').inner_text.should == ""
    response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/@id').inner_text.should == "s#{@common_name1.id}"
    response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name').inner_text.should == "#{@common_name1.name.string}"
    response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name/@scientific').inner_text.should == "false"
    response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name/@language').inner_text.should == @common_name1.language.iso_639_1
  end
end
