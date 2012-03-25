require File.dirname(__FILE__) + '/../../spec_helper'

def overviews_do_show
  get :show, :taxon_id => @testy[:taxon_concept].id.to_i
end

describe Taxa::OverviewsController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :testy
    @testy = EOL::TestInfo.load('testy')
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  end

  describe 'GET show' do
    it "should NOT be accessible if taxon concept id is not found" do
      expect{ get :show, :id => TaxonConcept.last.id + 1 }.should raise_error(ActiveRecord::RecordNotFound)
    end
    it "should NOT be accessible if taxon concept is unpublished" do
      expect{ get :show, :id => @testy[:unpublished_taxon_concept].id }.should raise_error(EOL::Exceptions::MustBeLoggedIn)
      expect{ get :show, { :id => @testy[:unpublished_taxon_concept].id },
                         { :user_id => @testy[:user].id } }.should raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should be accessible if taxon concept is published' do
      overviews_do_show
      response.redirected_to.should be_nil
      response.rendered[:template].should == "taxa/overviews/show.html.haml"
    end
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
