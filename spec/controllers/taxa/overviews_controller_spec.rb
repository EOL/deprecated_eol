require File.dirname(__FILE__) + '/../../spec_helper'

def overviews_do_show
  get :show, :taxon_id => @testy[:taxon_concept].id.to_i
end

describe Taxa::OverviewsController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :testy
    @testy = EOL::TestInfo.load('testy')
    SolrAPI.new($SOLR_SERVER, $SOLR_DATA_OBJECTS_CORE).delete_all_documents
    DataObject.all.each{ |d| d.update_solr_index }
  end

  describe 'GET show' do

    it 'should instantiate the taxon concept' do
      overviews_do_show
      assigns[:taxon_concept].should be_a(TaxonConcept)
    end
    it 'should instantiate summary text' do
      overviews_do_show
      assigns[:summary_text].should be_a(DataObject)
    end
    it 'should instantiate summary media' do
      overviews_do_show
      assigns[:media][0].should be_a(DataObject)
    end
    it 'should instantiate an assistive header' do
      overviews_do_show
      assigns[:assistive_section_header].should be_a(String)
    end
  end

end
