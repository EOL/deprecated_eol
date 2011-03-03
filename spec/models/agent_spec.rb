require File.dirname(__FILE__) + '/../spec_helper'

def agent_attributes
  @agent_attributes ||= { :username => 'quentin', :password => 'test', :password_confirmation => 'test' }
end

describe Agent do

  before(:all) do
    load_foundation_cache
    Agent.delete_all
    @agent = Agent.gen agent_attributes
    
    @contains_tc = TaxonConcept.gen # no need to do the build_taxon_concept thing
    @contains_he = HierarchyEntry.gen(:taxon_concept => @contains_tc)
    @doesnt_contain_tc = TaxonConcept.gen # no need to do the build_taxon_concept thing
    @doesnt_contain_he = HierarchyEntry.gen(:taxon_concept => @doesnt_contain_tc)
    resource = Resource.gen
    AgentsResource.gen(:agent => @agent, :resource => resource)
    event = HarvestEvent.gen(:resource => resource, :published_at => nil)
    HarvestEventsHierarchyEntry.gen(:harvest_event => event, :hierarchy_entry => @contains_he)
  end

  it 'authenticates' do
    Agent.authenticate('quentin', 'test').should == @agent
  end

  it 'works with reset password' do
    new_pass = @agent.reset_password!
    Agent.authenticate('quentin', new_pass).should == @agent.reload
  end

  it 'should set' do
    @agent.remember_me
    @agent.remember_token.should_not be_nil
    @agent.remember_token_expires_at.should_not be_nil
  end

  it 'unsets remember token' do
    @agent.remember_me
    @agent.remember_token.should_not be_nil
    @agent.forget_me
    @agent.remember_token.should be_nil
  end

  it 'remembers me for one week' do
    before = 1.week.from_now.utc
    @agent.remember_me_for 1.week
    after = 1.week.from_now.utc
    @agent.remember_token.should_not be_nil
    @agent.remember_token_expires_at.should_not be_nil
    @agent.remember_token_expires_at.between?(before, after).should be_true
  end

  it 'remembers me until one week' do
    time = 1.week.from_now.utc
    @agent.remember_me_until time
    @agent.remember_token.should_not be_nil
    @agent.remember_token_expires_at.should_not be_nil
    @agent.remember_token_expires_at.should == time
  end

  it 'remembers me default two weeks' do
    before = 2.weeks.from_now.utc
    @agent.remember_me
    after = 2.weeks.from_now.utc
    @agent.remember_token.should_not be_nil
    @agent.remember_token_expires_at.should_not be_nil
    @agent.remember_token_expires_at.between?(before, after).should be_true
  end

  it 'should NOT be ready for agreement without contacts' do
    agent=Agent.new(:project_name => 'Project')
    agent.content_partner = ContentPartner.gen :partner_complete_step => Time.now, :ipr_accept => 1,
                              :attribution_accept => 1, :roles_accept => 1
    agent.terms_agreed_to?.should be_true
    agent.ready_for_agreement?.should_not be_true
  end

  it "should be ready for agreement when they enter enough info" do 
    agent=Agent.new(:project_name => 'Project')
    agent.agent_contacts << AgentContact.gen
    agent.content_partner = ContentPartner.gen :partner_complete_step => Time.now, :ipr_accept => 1,
                              :attribution_accept => 1, :roles_accept => 1
    agent.terms_agreed_to?.should be_true
    # TODO - these need separate testing... (except agent_contacts.any?, which is a rubyism)
      agent.agent_contacts.any?.should be_true
      agent.content_partner.partner_complete_step?.should be_true
      agent.terms_agreed_to?.should be_true
    agent.ready_for_agreement?.should be_true
  end

  it "should not be ready for agreement before all info is entered and agreements are made" do
    agent=Agent.new(:project_name => 'Project')
    agent.agent_contacts << AgentContact.gen
    agent.content_partner = ContentPartner.gen :partner_complete_step => 0, :ipr_accept => 0,
                              :attribution_accept => 1, :roles_accept => 1
    agent.terms_agreed_to?.should_not be_true
    agent.ready_for_agreement?.should_not be_true
  end

  it 'should get all data_objects that came from an agents last harvest' do
    @agent       = Agent.gen
    @resource    = Resource.gen
    AgentsResource.gen(:agent => @agent, :resource => @resource)
    @first_event = HarvestEvent.gen(:resource => @resource)
    @first_datos = []
    5.times do
      @first_datos << DataObject.gen
      DataObjectsHarvestEvent.gen(:harvest_event => @first_event,
                                  :data_object   => @first_datos.last)
    end
    @last_event = HarvestEvent.gen(:resource => @resource)
    @last_datos = []
    5.times do
      @last_datos << DataObject.gen
      DataObjectsHarvestEvent.gen(:harvest_event => @last_event,
                                  :data_object   => @last_datos.last)
    end
    @agent.agents_data.map {|ob| ob.id}.sort.should == 
      @last_datos.map {|ob| ob.id}.sort
  end

  it 'should know if a taxon_concept was in its latest harvest event' do
    @agent.latest_unpublished_harvest_contains?(@contains_tc).should be_true    # Takes both a TaxonConcept...
    @agent.latest_unpublished_harvest_contains?(@contains_tc.id).should be_true # ...and just an ID
  end

  it 'should know if a taxon_concept was NOT in its latest harvest event' do
    @agent.latest_unpublished_harvest_contains?(@doesnt_contain_tc).should_not be_true    # Takes both a TaxonConcept...
    @agent.latest_unpublished_harvest_contains?(@doesnt_contain_tc.id).should_not be_true # ...and just an ID
  end
     
end
