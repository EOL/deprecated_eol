require File.dirname(__FILE__) + '/../spec_helper'

describe TaxaController do

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

end
