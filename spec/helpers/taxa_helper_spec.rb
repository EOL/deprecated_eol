require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe TaxaHelper do
  
  def render_partial
    @response = helper.paginate_results(@current_page)
  end
  
  it "should have serp_pagination class present" do
    @current_page = mock("search mock", :current_page => 1, :total_pages => 1)
    render_partial
    @response.should =~ /^<div class="serp_pagination">/
  end
  
  it "should have 5 pages of results present" do
    @current_page = mock("search mock", :current_page => 1, :total_pages => 5)
    render_partial
    @response.should_not =~ /page=1/
    @response.should =~ /page=2/
    @response.should =~ /page=3/
    @response.should =~ /page=4/
    @response.should =~ /page=5/
    @response.should_not =~ /page=6/
  end

  it "should reformat projects into 2 dimentional array" do
    projects = [1,2,3,4,5]
    helper.reformat_specialist_projects(projects).should == [[[1,2],[3,4],[5,nil]], 2]
  end

  it "should create link_text for specialis project" do
    collection_types = [CollectionType.gen(:label => 'Type1'), CollectionType.gen(:label => 'Type2')]
    collection = Collection.gen(:title => 'Collection title')
    collection_types.each do |ct|
      CollectionTypesCollection.gen(:collection_type => ct, :collection => collection)
    end
    helper.specialist_project_collection_link(collection).should == "Type1, Type2"
    empty_collection = Collection.gen(:title => "Empty Collection")
    helper.specialist_project_collection_link(empty_collection).should == "Empty Collection"
  end

end
