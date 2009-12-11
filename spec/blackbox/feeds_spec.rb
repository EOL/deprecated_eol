require File.dirname(__FILE__) + '/../spec_helper'

describe 'Curator Feeds' do
  before(:all) do
    Scenario.load('foundation')
    DataObject.delete_all
    @tc = build_taxon_concept()
  end

  it "should render: 'texts', 'images', 'comments', 'all' feeds" do
    ["/feeds/texts/", "/feeds/images/", "/feeds/comments/"].each do |feed_url|
      ['', @tc.id].each do |tc_id|
        res = RackBox.request("#{feed_url}#{tc_id}")
        res.success?.should be_true
        res.body.should have_tag("feed")
      end
    end
  end

  it 'should verify that comments feed for a species with no childen in tree only has comment for that species' do
    
  end
#  it 'should verify that images feed for a species with no childen in tree only has images for that species'
#  it 'should verify that text feed for a species with no childen in tree only has text for that species'
#
#  it 'should verify that comments feed for a species with childen in the tree has comments for itself and all its children'
#  it 'should verify that images feed for a species with childen in the tree has images for itself and all its children'
#  it 'should verify that text feed for a species with childen in the tree has text for itself and all its children'
#
#  it 'should verify that comments feed has comments for old and new version of re-harvested data'
  it 'should verify that all feed contains text, images, and comments' do
    result = RackBox.request("/feeds/all/#{@tc.id}")
    result.body.downcase.should include('new text')
    result.body.downcase.should include('new image')
    result.body.downcase.should include('new comment')

    result = RackBox.request("/feeds/all/")
    pp result.body
    result.body.downcase.should include('image')
    result.body.downcase.should include('new text')
    result.body.downcase.should include('new comment')
  end

end
