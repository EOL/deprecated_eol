require File.dirname(__FILE__) + '/../../spec_helper'

describe 'API:hierarchies' do
  before(:all) do
    load_foundation_cache
    @test_hierarchy = Hierarchy.gen(label: 'Some test hierarchy', browsable: 1)
    @test_hierarchy_entry_published = HierarchyEntry.gen(hierarchy: @test_hierarchy, identifier: 'Animalia',
      parent_id: 0, published: 1, visibility_id: Visibility.visible.id, rank: Rank.kingdom)
  end

  # not logging API anymore!
  # it 'should create an API log including API key' do
    # user = User.gen(api_key: User.generate_key)
    # check_api_key("/api/hierarchies/#{@test_hierarchy.id}?key=#{user.api_key}", user)
  # end

  it 'hierarchies should list the hierarchy roots' do
    response = get_as_xml("/api/hierarchies/#{@test_hierarchy.id}")
    our_result = response.xpath("//dc:title").inner_text.should == @test_hierarchy.label
    our_result = response.xpath("//dc:contributor").inner_text.should == @test_hierarchy.agent.full_name
    our_result = response.xpath("//dc:dateSubmitted").inner_text.should == @test_hierarchy.indexed_on.mysql_timestamp
    our_result = response.xpath("//dc:source").inner_text.should == @test_hierarchy.url
    our_result = response.xpath("//dwc:Taxon").length.should == 1
    our_result = response.xpath("//dwc:Taxon/dwc:taxonID").inner_text.should == @test_hierarchy_entry_published.id.to_s
    our_result = response.xpath("//dwc:Taxon/dwc:parentNameUsageID").inner_text.should == 0.to_s
    our_result = response.xpath("//dwc:Taxon/dwc:taxonConceptID").inner_text.should == @test_hierarchy_entry_published.taxon_concept_id.to_s
    our_result = response.xpath("//dwc:Taxon/dwc:scientificName").inner_text.should == @test_hierarchy_entry_published.name.string
    our_result = response.xpath("//dwc:Taxon/dwc:taxonRank").inner_text.should == @test_hierarchy_entry_published.rank.label

    response = get_as_json("/api/hierarchies/#{@test_hierarchy.id}.json")
    response['title'].should == @test_hierarchy.label
    response['contributor'].should == @test_hierarchy.agent.full_name
    response['dateSubmitted'].should == @test_hierarchy.indexed_on.mysql_timestamp
    response['source'].should == @test_hierarchy.url
    response['roots'].length.should == 1
    response['roots'][0]['taxonID'].should == @test_hierarchy_entry_published.id
    response['roots'][0]['parentNameUsageID'].should == 0
    response['roots'][0]['taxonConceptID'].should == @test_hierarchy_entry_published.taxon_concept_id
    response['roots'][0]['scientificName'].should == @test_hierarchy_entry_published.name.string
    response['roots'][0]['taxonRank'].should == @test_hierarchy_entry_published.rank.label
  end
end
