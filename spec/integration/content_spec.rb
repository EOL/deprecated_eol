require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'APIs' do
  describe 'Best Images' do
    before(:all) do
      EolScenario.load(:foundation)
      Capybara.reset_sessions!
      @image_1 = Factory.next(:image)
      @image_2 = Factory.next(:image)
      @image_3 = Factory.next(:image)
      @taxon_concept   = build_taxon_concept(
         :images          => [{:object_cache_url => @image_1, :data_rating => 5},
                              {:object_cache_url => @image_2, :data_rating => 5},
                              {:object_cache_url => @image_3, :data_rating => 5}])
      @id = @taxon_concept.id
    end
    
    after(:all) do
      @taxon_concept.destroy
    end
    
    it 'should generate the best images xml' do
      visit("/pages/#{@id}/best_images.xml")
      best_images_xml = Nokogiri::XML(body)
      best_images_xml.xpath('/eol:response', {'eol' => 'http://www.eol.org/transfer/content/0.2'}).should_not be_empty
      best_images_xml.xpath('/eol:response/eol:taxon', {'eol' => 'http://www.eol.org/transfer/content/0.2'}).should_not be_empty
      best_images_xml.xpath('/eol:response/eol:taxon', {'eol' => 'http://www.eol.org/transfer/content/0.2'}).length.should == 1
      best_images_xml.xpath('///eol:dataObject', {'eol' => 'http://www.eol.org/transfer/content/0.2'}).length.should == 1
    end
    
    it 'should limit the results based on parameter' do
      visit("/pages/#{@id}/best_images.xml?limit=3")
      best_images_xml = Nokogiri::XML(body)
      best_images_xml.xpath('///eol:dataObject', {'eol' => 'http://www.eol.org/transfer/content/0.2'}).length.should == 3
    end
    
    it 'should generate the best image html' do
      visit("/pages/#{@id}/best_images.html")
      body.should have_tag('img')
      body.should include('_large.jpg')
      body.should include('Generated on')
    end
  end
end
