require File.dirname(__FILE__) + '/../spec_helper'

def test_xml(xml, node, data)
  result = xml.xpath("/add/doc/field[@name='#{node}']").map {|n| n.content }
  result.sort.should == data.sort
end

describe 'Solr API' do

  describe ': TaxonConcepts' do
    before(:all) do
      load_foundation_cache
      Vetted.gen(:label => 'Trusted') unless Vetted.trusted
      trusted = Vetted.trusted
      @solr = SolrAPI.new($SOLR_SERVER, $SOLR_TAXON_CONCEPTS_CORE)
      @data = { :common_name => ['Atlantic cod', 'Pacific cod'],
                :preferred_scientific_name => ['Gadus mohua'],
                :taxon_concept_id => ['1'],
                :ancestor_taxon_concept_id => '3452345',
                :top_image_id => '123',
                :supercedure_id => 0, # This is not *required*, but the search specifies = 0, soooooo....
                :vetted_id => trusted.id,
                :published => 1 }
    end
  
    it 'should connect to solr server from environment' do
      @solr.action_uri.host.should == 'localhost'
      config_solr_path = ($SOLR_SERVER + $SOLR_TAXON_CONCEPTS_CORE).sub(/^.*?\/solr/, '/solr')
      @solr.action_uri.path.should == config_solr_path
    end
  
    it 'should be able to run search on the server' do
      @solr.delete_all_documents
      @solr.get_results("*:*")['numFound'].should == 0
    end
  
    it 'should convert ruby array or hash to solr-compatible xml' do
      res = @solr.build_solr_xml('add', @data)
      xml = Nokogiri::XML(res)  
      xml.xpath('/add/doc').should_not be_empty
      [:top_image_id, :preferred_scientific_name, :taxon_concept_id, :common_name, :ancestor_taxon_concept_id].each do |node|
        test_xml(xml, node, @data[node])
      end
    end
  
    it 'should add an index for a document on a call to #create' do
      res = @solr.create(@data)
      @solr.get_results("common_name:cod")['numFound'].should > 0
      @solr.get_results("ancestor_taxon_concept_id:3452345")['numFound'].should > 0
    end
  
    it 'should be able to send hashes as CSV file' do
      File.unlink(@solr.csv_path) if File.exists?(@solr.csv_path)
      File.exists?(@solr.csv_path).should == false
      
      @solr.delete_all_documents
      @solr.get_results("*:*")['numFound'].should == 0
      res = @solr.send_attributes({ 123 => { :vetted_id => 3, :published => 1 },
                                    456 => { :vetted_id => 2, :published => 0, :nonsense => 'anything' } }, true, false)
      # send attributes will create a CSV file to send to Solr
      File.exists?(@solr.csv_path).should == true
      File.open(@solr.csv_path, "r") do |f|
        line = f.gets
        # first line should include the valid fields sent
        line.should match('vetted_id')
        line.should match('published')
        # first line should also include fields in the schema NOT sent
        line.should match('supercedure_id')
        line.should match('preferred_scientific_name')
        # first line should NOT include the invalid fields
        line.should_not match('nonsense')
      end
      
      # now run a few searches to make sure the content made it to Solr
      @solr.get_results("*:*")['numFound'].should == 2
      @solr.get_results("published:true")['numFound'].should == 1
      @solr.get_results("published:false")['numFound'].should == 1
      
      File.unlink(@solr.csv_path) if File.exists?(@solr.csv_path)
    end
  end
  
  describe ': DataObjects' do
    before(:all) do
      load_foundation_cache
      @solr = SolrAPI.new($SOLR_SERVER, $SOLR_DATA_OBJECTS_CORE)
      @solr.delete_all_documents
    end
  
    it 'should create the data object index' do
      @taxon_concept = build_taxon_concept(:images => [{ :guid => 'a509ebdb2fc8083f3a33ea17985bae72', :published => 1 }])
      @data_object = DataObject.last
      @solr.build_data_object_index([@data_object])
      @solr.get_results("data_object_id:#{@data_object.id}")['numFound'].should == 1
    end
  end
  
  describe ': SiteSearch' do
    before(:all) do
      load_foundation_cache
      TaxonConcept.delete_all
      HierarchyEntry.delete_all
      Synonym.delete_all
      ContentPage.delete_all
      @scientific_name = "Something unique"
      @common_name = "Name not yet used"
      @test_taxon_concept = build_taxon_concept(:scientific_name => @scientific_name, :common_names => [@common_name])
      TaxonConcept.connection.execute("commit")
      TranslatedContentPage.gen(:title => "Test Content Page", :main_content => "Main Content Page", :left_content => "Left Content Page")
      @solr = SolrAPI.new($SOLR_SERVER, $SOLR_SITE_SEARCH_CORE)
      @solr.delete_all_documents
    end
    
    it 'should start with an empty core' do
      @solr.delete_all_documents
      @solr.get_results("*:*")['numFound'].should == 0
    end
    
    # NOTE - these numbers are based on the foundation scenario.  If these two specs are failing, and you changed
    # that scenaio file, it is OKAY (and recommended) to update these tests to the correct numbers.
    it 'should rebuild the core' do
      EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
      # names for preferred name, synonym, surrogate and common names
      @solr.get_results("*:*")['numFound'].should == 53
      @solr.get_results("resource_type:TaxonConcept AND resource_id:#{@test_taxon_concept.id}")['numFound'].should == 3
      @solr.get_results("keyword:#{@scientific_name}")['numFound'].should == 2
      @solr.get_results("keyword:#{@common_name}")['numFound'].should == 1
      @solr.get_results("resource_type:ContentPage")['numFound'].should == 2
    end
    
    it 'should reindex given model' do
      EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
      EOL::Solr::SiteSearchCoreRebuilder.reindex_model(TaxonConcept, @solr)
      @solr.get_results("*:*")['numFound'].should == 53
      @solr.get_results("resource_type:TaxonConcept AND resource_id:#{@test_taxon_concept.id}")['numFound'].should == 3
      @solr.get_results("keyword:#{@scientific_name}")['numFound'].should == 2
      @solr.get_results("keyword:#{@common_name}")['numFound'].should == 1
      EOL::Solr::SiteSearchCoreRebuilder.reindex_model(ContentPage, @solr)
      @solr.get_results("resource_type:ContentPage")['numFound'].should == 2
    end
    
  end
  
  describe ': BHL' do
    before(:all) do
      load_foundation_cache
      PublicationTitle.delete_all
      TitleItem.delete_all
      ItemPage.delete_all
      PageName.delete_all
      @solr = SolrAPI.new($SOLR_SERVER, $SOLR_BHL_CORE)
      @solr.delete_all_documents
      @test_taxon_concept = build_taxon_concept(:bhl => [])
      
      @publication = PublicationTitle.gen(:title => "Series publication title", :details => "publisher info",
        :start_year => 1700, :end_year => 2011)
      @title_item = TitleItem.gen(:publication_title => @publication, :volume_info => "v2. 1776")
      @item_page = ItemPage.gen(:title_item => @title_item, :year => 1776, :volume => 2, :issue => 4, :prefix => "Page",
        :number => 98)
      PageName.gen(:item_page => @item_page, :name => @test_taxon_concept.entry.name)
    end
    
    it 'should start with an empty core' do
      @solr.delete_all_documents
      @solr.get_results("*:*")['numFound'].should == 0
    end
    
    it 'should rebuild the core' do
      builder = EOL::Solr::BHLCoreRebuilder.new()
      builder.begin_rebuild
      # names for preferred name, synonym, surrogate and common names
      @solr.get_results("*:*")['numFound'].should == 1
      @solr.get_results("id:#{@item_page.id}")['numFound'].should == 1
      @solr.get_results("name_id:#{@test_taxon_concept.entry.name.id}")['numFound'].should == 1
      @solr.get_results("name_id:#{@test_taxon_concept.entry.name.id}")['numFound'].should == 1
      @solr.get_results("year:#{@item_page.year}")['numFound'].should == 1
      
      result = @solr.get_results("*:*")['docs'][0]
      result["number"].should == @item_page.number.to_s
      result["details"].should == @publication.details
      result["prefix"].should == @item_page.prefix
      result["end_year"].should == @publication.end_year.to_i
      result["title_item_id"].should == @title_item.id.to_s  # needs to be a string for grouping
      result["id"].should == @item_page.id
      result["volume"].should == @item_page.volume.to_s
      result["year"].should == @item_page.year.to_i
      result["publication_title"].should == @publication.title
      result["issue"].should == @item_page.issue.to_s
      result["publication_id"].should == @publication.id.to_s  # needs to be a string for grouping
      result["name_id"].should == [ @test_taxon_concept.entry.name.id ]
      result["volume_info"].should == @title_item.volume_info
      result["end_year"].should == @publication.end_year.to_i
    end
  end
  
end

