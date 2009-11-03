require File.dirname(__FILE__) + '/../spec_helper'
include EOL::Spec::Helpers

describe Search do
  
  Scenario.load :foundation
  
  before(:each) do
    @language = Factory(:language, :label => 'English')
  end
  
  describe "#new" do
    before(:each) do 
      q = "tiger"
      search_log_id = "42"
      search_type = "text"
  
      @params = {:q => q, :search_log_id => search_log_id}
      @request = ActionController::AbstractRequest.new
      @request = stub("request", :remote_ip => "127.0.0.1", :user_agent => "Mozilla", :request_uri => "/search")
      @user = mock_model(User, :language => @language, :vetted => true, :is_admin? => true, :vetted => false)
      # @user = User.first
      @agent = mock_model(Agent)
  
      @expected_params = {
        :search_term => q,
        :search_type => search_type,
        :parent_search_log_id => search_log_id
      }
    end
  
    it "should invoke SearchLog#log" do
      SearchLog.should_receive(:log).with(@expected_params, @request, @user)
      Search.new(@params, @request, @user, @agent, false)
    end
      
    it "should execute a query" do
      cf = CanonicalForm.gen :string => "tiger"
      nn = NormalizedName.gen :name_part => "tiger"
      Name.delete_all('string = "tiger"') # TODO - move this to the test AFTER which it's created and not cleaned up!
      nm = Name.gen :italicized => "ital", :canonical_form => cf, :string => "tiger", :canonical_verified => "cv"
      nl = NormalizedLink.gen :normalized_name => nn, :name => nm
      trusted = Vetted.trusted || Vetted.create(:label => 'Trusted') # For some reason, this didn't exist.
      tc = TaxonConcept.gen(:vetted => trusted, :published => "1")
      tcn = TaxonConceptName.gen(:taxon_concept => tc)
      tcc = TaxonConceptContent.gen(:taxon_concept => tc)
      # tc = EOL::TaxonConceptBuilder.new(:rank => 'kingdom', :canonical_form => 'Animalia', :common_name => 'tiger')
      # pp [:tc, tc.tc]
      # pp Search.new(@params, @request, @user, @agent)
    end
    
  end
end
