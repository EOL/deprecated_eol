require File.dirname(__FILE__) + '/../spec_helper'

describe TaxaController do
  
  before(:each) do
    Factory(:language, :label => 'English')
  end
  
  it "should report an invalid search term" do
    get :search
    assigns[:search].error_message.should == "Your search term was invalid."
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
