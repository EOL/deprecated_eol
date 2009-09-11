require File.dirname(__FILE__) + '/../spec_helper'

describe 'APIs' do
  Scenario.load :foundation

  # describe 'Taxon Concepts API' 
  # do
    # it 'a call to the URL should create .gz file' do
    #   file_dir = File.dirname(__FILE__) + "/../../public/content/tc_api.gz"
    # 
    #   RackBox.request("/content/tc_api/")
    #   File.exist?(file_dir).should eql(true)
    # end
  # end
  
  describe 'Highest-Rated Images API' do
    
    before(:all) do
      t1 = TaxonConcept.find(1)
      t1.destroy if t1                            
      @taxon_concept = build_taxon_concept(:id => 1)
      @taxon_concept.images.each {|i| i.data_rating = 5.0}
      @taxon_concept.images.each {|i| i.save}
      @taxon_concept_xml = Nokogiri::XML(RackBox.request("/pages/#{@taxon_concept.id}/best_images.xml").body)
    end
    
    it 'should serve XML on call to /pages/1/best_images.xml' do
      @taxon_concept_xml.at(:dataObject).inner_html.should_not be_empty
    end
  end
  
end
