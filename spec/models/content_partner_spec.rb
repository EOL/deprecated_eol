require File.dirname(__FILE__) + '/../spec_helper'

describe ContentPartner do

  before(:all) do
    truncate_all_tables
    load_foundation_cache

    @user = User.gen(:username => 'quentin', :password => 'test')
    @content_partner = ContentPartner.gen(:user => @user)

    @contains_tc = TaxonConcept.gen # no need to do the build_taxon_concept thing
    @contains_he = HierarchyEntry.gen(:taxon_concept => @contains_tc)
    @doesnt_contain_tc = TaxonConcept.gen # no need to do the build_taxon_concept thing
    @doesnt_contain_he = HierarchyEntry.gen(:taxon_concept => @doesnt_contain_tc)
    resource = Resource.gen(:content_partner => @content_partner)
    event = HarvestEvent.gen(:resource => resource, :published_at => nil)
    HarvestEventsHierarchyEntry.gen(:harvest_event => event, :hierarchy_entry => @contains_he)
  end

  it 'should NOT be ready for agreement without contacts' do
    user = User.gen(:given_name => 'Project')
    content_partner = ContentPartner.gen(:user => user, :partner_complete_step => Time.now, :ipr_accept => 1,
                              :attribution_accept => 1, :roles_accept => 1)
    content_partner.terms_agreed_to?.should be_true
    content_partner.ready_for_agreement?.should_not be_true
  end

  it "should be ready for agreement when they enter enough info" do
    user = User.gen(:given_name => 'Project')
    content_partner = ContentPartner.gen(:user => user, :partner_complete_step => Time.now, :ipr_accept => 1,
                              :attribution_accept => 1, :roles_accept => 1)
    content_partner.content_partner_contacts << ContentPartnerContact.gen(:content_partner => content_partner)
    content_partner.terms_agreed_to?.should be_true

    # TODO - these need separate testing... (except agent_contacts.any?, which is a rubyism)
    content_partner.content_partner_contacts.any?.should be_true
    content_partner.partner_complete_step?.should be_true
    content_partner.terms_agreed_to?.should be_true

    content_partner.ready_for_agreement?.should be_true
  end

  it "should not be ready for agreement before all info is entered and agreements are made" do
    user = User.gen(:given_name => 'Project')
    content_partner = ContentPartner.gen(:user => user, :partner_complete_step => 0, :ipr_accept => 0,
                              :attribution_accept => 1, :roles_accept => 1)
    content_partner.terms_agreed_to?.should_not be_true
    content_partner.ready_for_agreement?.should_not be_true
  end

  it 'should get all data_objects that came from an agents last harvest' do
    agent = Agent.gen()
    user = User.gen(:agent => agent)
    content_partner = ContentPartner.gen(:user => user)
    resource = Resource.gen(:content_partner => content_partner)
    first_event = HarvestEvent.gen(:resource => resource)
    first_datos = []
    5.times do
      first_datos << DataObject.gen
      DataObjectsHarvestEvent.gen(:harvest_event => first_event,
                                  :data_object   => first_datos.last)
    end
    last_event = HarvestEvent.gen(:resource => resource)
    last_datos = []
    5.times do
      last_datos << DataObject.gen
      DataObjectsHarvestEvent.gen(:harvest_event => last_event,
                                  :data_object   => last_datos.last)
    end

    content_partner.resources.first.latest_harvest_event.data_objects.map {|ob| ob.id}.sort.should ==
      last_datos.map {|ob| ob.id}.sort
  end

  it 'should know if a taxon_concept was in its latest harvest event' do
    @content_partner.latest_unpublished_harvest_contains?(@contains_tc).should be_true    # Takes both a TaxonConcept...
    @content_partner.latest_unpublished_harvest_contains?(@contains_tc.id).should be_true # ...and just an ID
  end

  it 'should know if a taxon_concept was NOT in its latest harvest event' do
    @content_partner.latest_unpublished_harvest_contains?(@doesnt_contain_tc).should_not be_true    # Takes both a TaxonConcept...
    @content_partner.latest_unpublished_harvest_contains?(@doesnt_contain_tc.id).should_not be_true # ...and just an ID
  end

end
