require File.dirname(__FILE__) + '/../../spec_helper'

describe Taxa::LiteratureController do

  before(:all) do
    # truncate_all_tables
    # LinkType.create_enumerated
    load_foundation_cache
    @test_taxon_concept = build_taxon_concept(:bhl => [], :comments => [], :sounds => [], :youtube => [], :flash => [], :toc => [])
    @publication = PublicationTitle.gen(:title => "Series publication title", :details => "publisher info",
      :start_year => 1700, :end_year => 2011)
    @title_item = TitleItem.gen(:publication_title => @publication, :volume_info => "v2. 1776")
    @item_page = ItemPage.gen(:title_item => @title_item, :year => 1776, :volume => 2, :issue => 4, :prefix => "Page",
      :number => 98)
    PageName.gen(:item_page => @item_page, :name => @test_taxon_concept.entry.name)
    
    full_ref = 'This is the reference text that should show up'
    url_identifier = 'some/url.html'
    doi_identifier = '10.12355/foo/bar.baz.230'
    bad_identifier = 'you should not see this identifier'
    @test_taxon_concept.data_objects[0].refs << ref = Ref.gen(:full_reference => full_ref, :published => 1, :visibility => Visibility.visible)
    builder = EOL::Solr::BHLCoreRebuilder.new()
    builder.begin_rebuild
  end

  shared_examples_for 'taxa/literature controller' do
    it 'should instantiate section for assistive header' do
      assigns[:assistive_section_header].should be_a(String)
    end
    it 'should instantiate the taxon concept' do
      assigns[:taxon_concept].should == @test_taxon_concept
    end
  end

  describe 'GET show' do
    before :each do
      get :show, :taxon_id => @test_taxon_concept.id
    end
    it_should_behave_like 'taxa/literature controller'
    it 'should instantiate common names' do
      assigns[:references].should be_a(Array)
      assigns[:references].first.should be_a(Ref)
    end
  end

  describe 'GET bhl' do
    before :each do
      get :bhl, :taxon_id => @test_taxon_concept.id
    end
    it_should_behave_like 'taxa/literature controller'
    it 'should query Solr for BHL references' do
      assigns[:bhl_results].should be_a(Hash)
      assigns[:bhl_results][:total].should == 1
      assigns[:bhl_results][:results].first['id'].should == @item_page.id
      assigns[:bhl_results][:results].first['year'].should == @item_page.year
    end
  end
  
  describe 'GET bhl_title' do
    before :each do
      get :bhl_title, :taxon_id => @test_taxon_concept.id, :title_item_id => @title_item.id
    end
    it_should_behave_like 'taxa/literature controller'
    it 'should get item info from Solr' do
      assigns[:bhl_title_results].should be_a(Hash)
      assigns[:bhl_title_results][:total].should == 1
      assigns[:bhl_title_results][:results].first['title_item_id'].should == @title_item.id.to_s
      assigns[:bhl_title_results][:results].first['volume_info'].should == @title_item.volume_info
    end
  end

end
