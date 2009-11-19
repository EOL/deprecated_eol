require File.dirname(__FILE__) + '/../spec_helper'

describe 'Curator Feeds' do
  before(:all) do
    Scenario.load('foundation')
  end

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
    tc = build_taxon_concept
    result = RackBox.request("/feeds/all/#{tc.id}")
    result.body.downcase.should include('new text')
    result.body.downcase.should include('new image')

    #result = RackBox.request("/feeds/all/")
    #puts result.body
    #result.body.downcase.should include('new comment')
  end

end
