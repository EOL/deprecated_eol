require "spec_helper"

describe TaxaController do

  describe 'GET show' do
    it "should permanently redirect to overview" do
      taxon_concept = double(TaxonConcept, id: 1)
      taxon_concept.stub(:published?).and_return(true)
      get :show, :id => taxon_concept.id
      expect(response).to redirect_to(taxon_overview_path(taxon_concept.id))
    end

    it "should redirect to search if taxon id is not an integer" do
      get :show, :id => 'tiger'
      expect(response).to redirect_to(search_path(:q => 'tiger'))
    end
  end

end
