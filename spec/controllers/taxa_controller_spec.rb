require File.dirname(__FILE__) + '/../spec_helper'

def overviews_do_show
  get :show, :taxon_id => @testy[:taxon_concept].id.to_i
end

describe TaxaController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :testy
    @testy = EOL::TestInfo.load('testy')
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  end

  describe 'GET show' do
    it "should permanently redirect to overview" do
      taxon_concept = stub_model(TaxonConcept)
      taxon_concept.stub!(:published?).and_return(true)
      get :show, :id => taxon_concept.id
      response.redirected_to.should == taxon_overview_path(taxon_concept.id)
    end

    it "should redirect to search if taxon id is not an integer" do
      get :show, :id => 'tiger'
      response.redirected_to.should == search_path(:id => 'tiger')
    end
  end

  describe 'GET overview' do
    it "should NOT be accessible if taxon concept id is not found" do
      expect{ get :overview, :id => TaxonConcept.last.id + 1 }.should raise_error(ActiveRecord::RecordNotFound)
    end
    it "should NOT be accessible if taxon concept is unpublished" do
      expect{ get :overview, :id => @testy[:unpublished_taxon_concept].id }.should raise_error(EOL::Exceptions::MustBeLoggedIn)
      expect{ get :overview, { :id => @testy[:unpublished_taxon_concept].id },
                         { :user_id => @testy[:user].id } }.should raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should be accessible if taxon concept is published' do
      overviews_do_show
      response.redirected_to.should be_nil
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
    it 'should instantiate summary media to include image map if exists' do
      image_map = DataObject.gen(:data_type_id => DataType.image.id, :data_subtype_id => DataType.map.id)
      overviews_do_show
      assigns[:media].last.should_not == image_map
      image_map.add_curated_association(@testy[:curator], @testy[:taxon_concept].entry)
      EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
      overviews_do_show
      assigns[:media].last.should == image_map
    end

  end

end
