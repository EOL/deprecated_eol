require File.dirname(__FILE__) + '/../../spec_helper'

def details_do_index
  get :index, :taxon_id => @testy[:taxon_concept].id.to_i
end

describe Taxa::DetailsController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :testy
    @testy = EOL::TestInfo.load('testy')
    # rebuild the Solr DataObject index
    SolrAPI.new($SOLR_SERVER, $SOLR_DATA_OBJECTS_CORE).delete_all_documents
    DataObject.all.each{ |d| d.update_solr_index }
  end

  describe 'GET index' do

    it 'should instantiate the taxon concept' do
      details_do_index
      assigns[:taxon_concept].should be_a(TaxonConcept)
    end
    it 'should instantiate the details Array containing text data objects and special content' do
      details_do_index
      assigns[:text_objects].should be_a(Array)
      assigns[:text_objects].take_while{|d| d.should be_a(DataObject)}.should == assigns[:text_objects]
    end
    it 'should instantiate a table of contents' do
      details_do_index
      assigns[:toc_items_to_show].should be_a(Array)
      assigns[:toc_items_to_show].include?(@testy[:overview]).should be_true # TocItem with content should be included
      assigns[:toc_items_to_show].include?(@testy[:toc_item_4]).should be_false # TocItem without content should be excluded
    end
    it 'should instantiate an exemplar image'
    it 'should instantiate an assistive header' do
      details_do_index
      assigns[:assistive_section_header].should be_a(String)
    end

  end

end
