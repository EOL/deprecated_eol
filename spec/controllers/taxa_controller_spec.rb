require File.dirname(__FILE__) + '/../spec_helper'

def overviews_do_show
  get :overview, :id => @testy[:taxon_concept].id.to_i
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
      expect(response).to redirect_to(overview_taxon_path(taxon_concept.id))
    end

    it "should redirect to search if taxon id is not an integer" do
      get :show, :id => 'tiger'
      expect(response).to redirect_to(search_path(:q => 'tiger'))
    end
  end

  describe 'GET overview' do
    it "should NOT be accessible if taxon concept id is not found" do
      expect{ get :overview, :id => TaxonConcept.last.id + 1 }.to raise_error(ActiveRecord::RecordNotFound)
    end
    it "should NOT be accessible if taxon concept is unpublished" do
      expect{ get :overview, :id => @testy[:unpublished_taxon_concept].id }.to raise_error(EOL::Exceptions::MustBeLoggedIn)
      expect{ get :overview, { :id => @testy[:unpublished_taxon_concept].id },
                         { :user_id => @testy[:user].id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should be accessible if taxon concept is published' do
      overviews_do_show
      response.status.should == 200
    end
    it 'should instantiate the taxon concept and page' do
      overviews_do_show
      assigns[:taxon_concept].should be_a(TaxonConcept)
      assigns[:taxon_page].should be_a(TaxonPage)
    end
    it 'should instantiate an assistive header' do
      overviews_do_show
      assigns[:assistive_section_header].should be_a(String)
    end
    # Note: I removed the map test, since this is now tested in TaxonPage.

  end

  # This seems slightly misplaced, but, in fact, we need a controller spec to test this...
  describe "TaxonPage links" do

    before(:all) do
      @taxon_concept = TaxonConcept.gen # Doesn't need to be anything fancy, here.
      @entry = HierarchyEntry.gen
      @user = User.gen
      @taxon_page = TaxonPage.new(@taxon_concept, @user)
      @taxon_page_with_entry = TaxonPage.new(@taxon_concept, @user, @entry)
    end

    it 'should link to the overview just like the taxon_concept' do
      overview_taxon_path(@taxon_concept).should == overview_taxon_path(@taxon_page)
    end

    it 'should link to the selected hierarchy entry view just like the taxon_concept' do
      overview_taxon_entry_path(@taxon_concept, @entry).should == overview_taxon_path(@taxon_page_with_entry)
    end

    # I don't want to test every single link, just the common one (overview) and something more complicated:
    it 'should link to the common names just like the taxon_concept' do
      common_names_taxon_names_path(@taxon_concept).should ==
        common_names_taxon_names_path(@taxon_page)
    end

    # I don't want to test every single link, just the common one (overview) and something more complicated:
    it 'should link to the selected hierarhcy entry view of common names just like the taxon_concept' do
      common_names_taxon_entry_names_path(@taxon_concept, @entry).should ==
        common_names_taxon_names_path(@taxon_page_with_entry)
    end

  end

end
