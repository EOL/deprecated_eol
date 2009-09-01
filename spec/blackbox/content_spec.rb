require File.dirname(__FILE__) + '/../spec_helper'

describe 'APIs' do
  Scenario.load :foundation

  describe 'Taxon Concepts API' do
    # it 'a call to the URL should create .gz file' do
    #   file_dir = File.dirname(__FILE__) + "/../../public/content/tc_api.gz"
    # 
    #   RackBox.request("/content/tc_api/")
    #   File.exist?(file_dir).should eql(true)
    # end
  end
  
  describe 'Highest-Rated Images API' do
    # # begin
    # tc = build_taxon_concept(:id => 1) 
    # # rescue
    # #   #there's already a tc with that id
    # # end      
    #    
    # it 'a call to the URL should create .gz file' do
    #   file_dir = File.dirname(__FILE__) + "/../../public/content/hr_images_api.gz"
    #   RackBox.request("/content/highest_rated_images_api?id=1/")
    #   File.exist?(file_dir).should eql(true)
    # end
    # 
  end
  
end
