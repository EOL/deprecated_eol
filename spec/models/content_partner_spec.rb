require "spec_helper"

describe ContentPartner do

  before(:all) do
    load_foundation_cache

    @user = User.gen(username: 'quentin', password: 'test')
    @content_partner = ContentPartner.gen(user: @user)

    @contains_tc = TaxonConcept.gen # no need to do the build_taxon_concept thing
    @contains_he = HierarchyEntry.gen(taxon_concept: @contains_tc)
    @doesnt_contain_tc = TaxonConcept.gen # no need to do the build_taxon_concept thing
    @doesnt_contain_he = HierarchyEntry.gen(taxon_concept: @doesnt_contain_tc)
    resource = Resource.gen(content_partner: @content_partner)
    event = HarvestEvent.gen(resource: resource, published_at: nil)
    HarvestEventsHierarchyEntry.gen(harvest_event: event, hierarchy_entry: @contains_he)
  end

  it 'should get all data_objects that came from an agents last harvest' do
    agent = Agent.gen()
    user = User.gen(agent: agent)
    content_partner = ContentPartner.gen(user: user)
    resource = Resource.gen(content_partner: content_partner)
    first_event = HarvestEvent.gen(resource: resource)
    first_datos = []
    5.times do
      first_datos << DataObject.gen
      DataObjectsHarvestEvent.gen(harvest_event: first_event,
                                  data_object: first_datos.last)
    end
    last_event = HarvestEvent.gen(resource: resource)
    last_datos = []
    5.times do
      last_datos << DataObject.gen
      DataObjectsHarvestEvent.gen(harvest_event: last_event,
                                  data_object: last_datos.last)
    end

    content_partner.resources.first.latest_harvest_event.data_objects.map {|ob| ob.id}.sort.should ==
      last_datos.map {|ob| ob.id}.sort
  end

  it "should know when it has resources that have unpublished content" do
    cp = ContentPartner.gen(user: @user)
    cp.unpublished_content?.should be_false # no resource means no content so we return false
    Rails.cache.clear
    resource = Resource.gen(content_partner: cp)
    cp.reload
    cp.unpublished_content?.should be_true
    Rails.cache.clear
    event = HarvestEvent.gen(resource: resource, published_at: nil)
    cp.resources.reload
    event.resource.reload
    cp.unpublished_content?.should be_true
    Rails.cache.clear
    event.update_attributes(publish: true)
    cp.resources.reload
    event.resource.reload
    cp.unpublished_content?.should be_true
    Rails.cache.clear
    event.update_attributes(published_at: Time.now, publish: false)
    cp.resources.reload
    event.resource.reload
    cp.unpublished_content?.should be_false
    Rails.cache.clear
    Resource.gen(content_partner: cp)
    cp.reload
    cp.unpublished_content?.should be_true
  end

  it "should know the date of the last action taken" do
    cp = ContentPartner.gen(user: @user)
    ContentPartnerAgreement.gen(content_partner_id: cp.id, created_at: 4.hours.ago, updated_at: 4.hours.ago)
    ContentPartnerContact.gen(content_partner_id: cp.id, created_at: 3.hours.ago, updated_at: 3.hours.ago)
    Resource.gen(content_partner_id: cp.id, created_at: 2.hours.ago, updated_at: nil)
    last_action = Time.now
    Resource.gen(content_partner_id: cp.id, created_at: 1.hour.ago, updated_at: last_action)
    cp.reload
    cp.last_action.utc.strftime("%Y-%m-%d %H:%M:%S").should == last_action.utc.strftime("%Y-%m-%d %H:%M:%S")
  end

end
