require File.dirname(__FILE__) + '/../spec_helper'

def test_xml(xml, node, data)
  result = xml.xpath("/add/doc/field[@name='#{node}']").map {|n| n.content }
  result.sort.should == data.sort
end

describe SolrAPI do
  before(:all) do
    Vetted.gen(:label => 'Trusted') unless Vetted.trusted
    trusted = Vetted.trusted
    @solr = SolrAPI.new
    @data = {:common_name => ['Atlantic cod', 'Pacific cod'],
             :preferred_scientific_name => ['Gadus mohua'],
             :taxon_concept_id => ['1'],
             :top_image_id => '123',
             :supercedure_id => 0, # This is not *required*, but the search specifies = 0, soooooo....
             :vetted_id => trusted.id,
             :published => 1}
  end

  it 'should connect to solr server from environment' do
    @solr.server_url.host.should == 'localhost'
    @solr.server_url.path.should == '/solr'
  end

  it 'should be able to run search on the server' do
    @solr.delete_all_documents
    @solr.get_results("*:*")['numFound'].should == 0
  end

  it 'should convert ruby array or hash to solr-compatible xml' do
    res = @solr.build_solr_xml('add', @data)
    xml = Nokogiri::XML(res)  
    xml.xpath('/add/doc').should_not be_empty
    [:top_image_id, :preferred_scientific_name, :taxon_concept_id, :common_name].each do |node|
      test_xml(xml, node, @data[node])
    end
  end

  it 'should add an index for a document on a call to #create' do
    res = @solr.create(@data)
    @solr.get_results("common_name:cod")['numFound'].should > 0
  end

end
