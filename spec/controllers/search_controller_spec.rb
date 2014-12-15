require "spec_helper"

describe SearchController do
  
  render_views
    
  describe 'index' do
    before(:all) do
      truncate_all_tables
      Language.create_english
    end
  end

  it "should find no results on an empty search" do
    Language.create_english
    get :index, :q => ''
    assigns[:all_results].should == []
  end
  
  describe "taxon autocomplete" do
    before(:all) do
      truncate_all_tables
      load_foundation_cache
      @name = Name.first
      @name.update_attributes(string: "cat")
      @taxon = TaxonConcept.gen
      @taxon_name = TaxonConceptName.gen(name: @name, taxon_concept: @taxon)
      EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
    end
      
    it "should return suggestions when user misspell taxon name" do
      get :autocomplete_taxon, { term: "hat" }
      expect(response.body).to have_selector('h2', text: I18n.t(:did_you_mean, :suggestions => nil))
      expect(response.body).to have_selector('span', include: "Alternative name:Cat")
    end
  end

end
