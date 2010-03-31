require File.dirname(__FILE__) + '/../spec_helper'

def hijack_search_for_tiger
  TaxonConcept.should_receive(:search_with_pagination).at_least(1).times.and_return(@common_collection.paginate({:page => 1, :per_page => 10}))
  get 'search', :q => 'tiger'
end

describe TaxaController do
  
  describe 'search' do

    before(:all) do
      Scenario.load :search_with_duplicates
      @tc_id                   = SearchScenarioResults.tc_id
      @new_common_name         = SearchScenarioResults.new_common_name
      @ancestor_concept        = SearchScenarioResults.ancestor_concept
      @parent_concept          = SearchScenarioResults.parent_concept
      @taxon_concept           = SearchScenarioResults.taxon_concept
      @duplicate_taxon_concept = SearchScenarioResults.duplicate_taxon_concept
      @query_results           = SearchScenarioResults.query_results

      # We call it with our bogus results:
      @common_collection = EOL::SearchResultsCollection.new(@query_results, :querystring => 'tiger', :type => :common)
    end

    describe 'with duplicates' do

      integrate_views # Note I am NOT using RackBox for these examples; faster.

      it 'should show the source hierarchy on the duplicates' do
        hijack_search_for_tiger
        response.should have_tag('span.recognized_by', :text => "Taxon recognized by #{@taxon_concept.entry.hierarchy.label}")
      end

      it 'should show the parent taxon_concept of the duplicates' do
        hijack_search_for_tiger
        response.should have_tag('div.parent', :text => @parent_concept.scientific_name)
      end

      it 'should show the ancestor (grandparent) taxon_concept of the duplicates' do
        hijack_search_for_tiger
        response.should have_tag('div.ancestor', :text => @ancestor_concept.scientific_name)
      end

      it 'should add the "duplicate" class to the result div when there are duplicates' do
        hijack_search_for_tiger
        response.should have_tag('div.duplicate')
      end

    end

  end

  it "should find no results on an empty search" do
    Factory(:language, :label => 'English') # Required to make the get run.
    get :search
    assigns[:all_results].should == []
  end
  
  describe "ACL rules for pages" do
    
    def accessible_page?(taxon_concept)
      controller.send("accessible_page?", taxon_concept)      
    end
    
    describe "for non-agent users" do
      
      before(:each) do
        # There is no agent!
        controller.current_agent = nil
      end
      
      it "should NOT be accessible if taxon_concept is nil" do
        accessible_page?(nil).should_not be_true
      end

      it "should NOT be accessible if taxon_concept is unpublished" do
        taxon_concept = stub_model(TaxonConcept)
        taxon_concept.stub!(:published?).and_return(false)
        accessible_page?(taxon_concept).should_not be_true
      end

      it 'should be accessible if taxon concept is published' do
        taxon_concept = stub_model(TaxonConcept)
        taxon_concept.stub!(:published?).and_return(true)
        accessible_page?(taxon_concept).should be_true
      end

    end
    
    describe "for agents accessing an unpublished taxon_concept" do

      before(:each) do
        @taxon_concept = stub_model(TaxonConcept)
        @taxon_concept.stub!(:published?).and_return(false)
        controller.current_agent = mock_model(Agent)
      end

      it "should NOT be accessible if the taxon_concept is referenced by the latest harvest entry" do
        controller.current_agent.stub!(:latest_unpublished_harvest_contains?).with(@taxon_concept.id).and_return(true) # ref
        accessible_page?(@taxon_concept).should be_true
      end
      
      it "should NOT not be accessible if the taxon_concept is not referenced by the latest harvest entry" do
        controller.current_agent.stub!(:latest_unpublished_harvest_contains?).with(@taxon_concept.id).and_return(false) # not ref
        accessible_page?(@taxon_concept).should_not be_true
      end

    end

  end

end
