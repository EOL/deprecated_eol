require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'APIs' do
  describe 'Best Images' do
    before(:all) do
        #Scenario.load :foundation

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
      @best_images_xml = Nokogiri::XML(RackBox.request("/pages/#{@id}/best_images.xml").body)  
      @best_images_xml.xpath('/eol:response', {'eol' => 'http://www.eol.org/transfer/content/0.2'}).should_not be_empty
      @best_images_xml.xpath('/eol:response/eol:taxon', {'eol' => 'http://www.eol.org/transfer/content/0.2'}).should_not be_empty
      @best_images_xml.xpath('/eol:response/eol:taxon', {'eol' => 'http://www.eol.org/transfer/content/0.2'}).length.should == 1
      @best_images_xml.xpath('///eol:dataObject', {'eol' => 'http://www.eol.org/transfer/content/0.2'}).length.should == 1
    end
    
    it 'should limit the results based on parameter' do
      @best_images_xml = Nokogiri::XML(RackBox.request("/pages/#{@id}/best_images.xml?limit=3").body)  
      @best_images_xml.xpath('///eol:dataObject', {'eol' => 'http://www.eol.org/transfer/content/0.2'}).length.should == 3
    end
    
    it 'should generate the best image html' do
      @result = RackBox.request("/pages/#{@id}/best_images.html")
      @result.body.should have_tag('img')
      #@result.body.should include('_large.jpg')
      @result.body.should include('.eol.org/content')
      @result.body.should include('Generated on')
    end
  end
end
