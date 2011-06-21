require File.dirname(__FILE__) + '/../spec_helper'

def hijack_search_for_tiger
  TaxonConcept.should_receive(:search_with_pagination).at_least(1).times.and_return(@common_collection.paginate({:page => 1, :per_page => 10}))
  get 'search', :q => 'tiger'
end

describe TaxaController do

  describe 'search' do

    before(:all) do
      truncate_all_tables
      Language.create_english
      load_scenario_with_caching :search_with_duplicates
      results = EOL::TestInfo.load('search_with_duplicates')
      @tc_id                   = results[:tc_id]
      @new_common_name         = results[:new_common_name]
      @ancestor_concept        = results[:ancestor_concept]
      @parent_concept          = results[:parent_concept]
      @taxon_concept           = results[:taxon_concept]
      @duplicate_taxon_concept = results[:duplicate_taxon_concept]
      @query_results           = results[:query_results]

      # We call it with our bogus results:
      @common_collection = EOL::SearchResultsCollection.new(@query_results, :querystring => 'tiger', :type => :common)
    end

    describe 'with duplicates' do

      it 'should show the source hierarchy on the duplicates (NOT ACCORDING TO V2 DESIGN - OBSOLETE?' do
        hijack_search_for_tiger
        assigns[:all_results].select{|r| r['recognized_by'] == @taxon_concept.entry.hierarchy.label}.count.should > 0
      end

      it 'should show the parent taxon_concept of the duplicates' do
        hijack_search_for_tiger
        assigns[:all_results].select{|r| r['parent_scientific'] == @parent_concept.scientific_name}.count.should > 0
      end

      it 'should show the ancestor (grandparent) taxon_concept of the duplicates' do
        hijack_search_for_tiger
        assigns[:all_results].select{|r| r['ancestor_scientific'] == @ancestor_concept.scientific_name}.count.should > 0
      end

    end

  end

  it "should find no results on an empty search" do
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
