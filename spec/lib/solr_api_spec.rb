require File.dirname(__FILE__) + '/../spec_helper'

def test_xml(xml, node, data)
  result = xml.xpath("/add/doc/field[@name='#{node}']").map {|n| n.content }
  result.sort.should == data.sort
end

describe 'Solr API' do
  before(:all) do
    truncate_all_tables
    load_foundation_cache
  end
  
  after(:all) do
    truncate_all_tables
  end
  
  describe ': TaxonConcepts' do
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
      config_solr_path = $SOLR_SERVER.sub(/^.*?\/solr/, '/solr')
      @solr.server_url.path.should == config_solr_path
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


  describe ': DataObjects' do
    before(:all) do
      @solr = SolrAPI.new($SOLR_SERVER_DATA_OBJECTS)
      @solr.delete_all_documents
    end

    it 'should create the data object index' do
      @taxon_concept = build_taxon_concept(:images => [{:guid => 'a509ebdb2fc8083f3a33ea17985bae72', :visibility_id => Visibility.preview.id}])
      @data_object = DataObject.last
      @solr.build_data_object_index([@data_object])
      @solr.get_results("data_object_id:#{@data_object.id}")['numFound'].should == 1
    end
  end
end

