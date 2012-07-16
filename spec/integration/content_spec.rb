require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'


describe 'MediaRSS Feed' do
  before(:all) do
    load_foundation_cache
    tc = build_taxon_concept
    @taxon_concept = TaxonConcept.find(tc.id, :include => {:top_concept_images => :data_object})
    @tc_name = @taxon_concept.quick_scientific_name(:normal)
    # we test for image URLs, so we need a consistent URL to look for
    @original_content_server_list = $CONTENT_SERVERS
    $CONTENT_SERVERS = ['http://content1.eol.org']
  end

  after(:all) do
    $CONTENT_SERVERS = @original_content_server_list
  end

  it 'should generate a proper MediaRSS feed' do
    visit("/content/mediarss/#{@taxon_concept.id}")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//channel/title').inner_text.should == 'Encyclopedia of Life images for ' + @tc_name
    xml_response.xpath('//channel/description').inner_text.should == 'Encyclopedia of Life images'
    xml_response.xpath('//channel/link').inner_text.should == url_for(:controller => "/", :only_path => false)
    xml_response.xpath('//channel/atom:link/@type').inner_text.should == 'application/rss+xml'
    xml_response.xpath('//channel/atom:link/@href').inner_text.should == url_for(:controller => 'content', :action => 'mediarss', :id => @taxon_concept.id)

    @taxon_concept.top_concept_images.each do |tci|
      xml_response.xpath("//channel/item[guid='#{tci.data_object.guid}']").length.should == 1
      xml_response.xpath("//channel/item[guid='#{tci.data_object.guid}'][last()]/link").inner_text.should ==
        xml_response.xpath("//channel/item[guid='#{tci.data_object.guid}'][last()]/permalink").inner_text
      xml_response.xpath("//channel/item[guid='#{tci.data_object.guid}'][last()]/permalink").inner_text.should ==
        data_object_url(tci.data_object.id)
      xml_response.xpath("//channel/item[guid='#{tci.data_object.guid}'][last()]/media:thumbnail/@url").inner_text.should ==
        ContentServer.image_cache_path(tci.data_object['object_cache_url'], '98_68')
      xml_response.xpath("//channel/item[guid='#{tci.data_object.guid}'][last()]/media:content/@url").inner_text.should ==
        ContentServer.image_cache_path(tci.data_object['object_cache_url'], :orig)
    end
  end
end

describe "Donation" do
  it "should render entry donation page" do
    visit("/content/donate")
    page.status_code.should == 200
    body.should include "Donate"
  end

  it "should render complete donation page" do
    visit("/content/donate_complete")
    page.status_code.should == 200
    body.should include("Thank you")
  end
end
