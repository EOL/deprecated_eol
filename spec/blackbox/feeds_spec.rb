require File.dirname(__FILE__) + '/../spec_helper'

def h(str)
  CGI.escapeHTML str
end

describe 'Curator Feeds' do
  before(:all) do
    Scenario.load('foundation')
    DataObject.delete_all
    Comment.delete_all
    @tc = build_taxon_concept()
    @text = @tc.data_objects.delete_if{|d| d.data_type_id != DataType.text.id}
    @images = @tc.data_objects.delete_if{|d| d.data_type_id != DataType.image.id}
    @feeds = ["/feeds/text/", "/feeds/images/", "/feeds/comments/", "/feeds/all/"]
  end
  after(:all) do
    truncate_all_tables
  end
  
  it "should render: 'text', 'images', 'comments', 'all' feeds" do
    @feeds.each do |feed_url|
      res = request("#{feed_url}#{@tc.id}")
      res.success?.should be_true
      res.body.should have_tag("feed")
    end
  end
  
  it "should show information in a time descentind order" do
    @feeds.each do |feed_url|
      res = request(feed_url)
      dates = Nokogiri.XML(res.body).xpath("//xmlns:updated").map {|i| Time.parse(i.text)}
      dates.should == dates.sort.reverse
    end
  end
  
  # this test is strange. the whole spec could use rewriting
  # it "should should only information about a specific species if species are selected" do
  #   #Brittle test, may be is should be removed...
  #   # Wish we had a better way to see if all info is about the same species. 
  #   # Picking species name from the title and mangle it to get a canonical name
  #   
  #   res = request("/feeds/all/#{@tc.id}")
  #   titles =  Nokogiri.XML(res.body).xpath("//xmlns:title").map {|i| i.text.match /new\s+(image|text|comment|)\s+for\s+(.*)\s*$/i}
  #   titles = titles.select {|i| i}.map {|i| i[2].strip.split(/\s+/)[0..1].join(" ")}
  #   titles.uniq.size.should == 1
  # end

#  it 'should verify that comments feed for a species with no childen in tree only has comment for that species'

#  it 'should verify that images feed for a species with no childen in tree only has images for that species'
#  it 'should verify that text feed for a species with no childen in tree only has text for that species'
#
#  it 'should verify that comments feed for a species with childen in the tree has comments for itself and all its children'
#  it 'should verify that images feed for a species with childen in the tree has images for itself and all its children'
#  it 'should verify that text feed for a species with childen in the tree has text for itself and all its children'
#
#  it 'should verify that comments feed has comments for old and new version of re-harvested data'

  it 'should verify that all feed contains text, images, and comments' do
    result = request("/feeds/all/#{@tc.id}")
    result.body.should include(h @text[0].description)
    result.body.should include(h @images[0].description)
    #result.body.downcase.should include('new comment')
    
    #result = request("/feeds/all/")
    #result.body.downcase.should include('new image')  don't get any images in first 100 results 
    #result.body.downcase.should include('new text')
    #result.body.downcase.should include('new comment')
  end

end
