require File.dirname(__FILE__) + '/../../spec_helper'

describe 'API:provider_hierarchies' do
  before(:all) do
    @test_hierarchy = Hierarchy.gen(label: 'Some test hierarchy', browsable: 1)
  end

  # not logging API anymore!
  # it 'should create an API log including API key' do
    # user = User.gen(api_key: User.generate_key)
    # check_api_key("/api/provider_hierarchies?key=#{user.api_key}", user)
  # end

  it 'provider_hierarchies should return a list of all providers' do
    response = get_as_xml("/api/provider_hierarchies")
    our_result = response.xpath("//hierarchy[@id='#{@test_hierarchy.id}']")
    our_result.length.should == 1
    our_result.inner_text.should == @test_hierarchy.label

    response = get_as_json("/api/provider_hierarchies.json")
    response.length.should > 0
    response.collect{ |r| r['id'].to_i == @test_hierarchy.id && r['label'] == @test_hierarchy.label }.length == 2
  end
end
