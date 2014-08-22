# encoding: utf-8
# EXEMPLAR

describe ContentPartner do

  before(:all) do
    load_foundation_cache
  end

  let(:user) { User.gen }
  subject { ContentPartner.gen(user: user) }

  it "has user" do
    expect(subject.user).to be_kind_of User
  end

  it "has status" do
    expect(subject.content_partner_status).to eq ContentPartnerStatus.active
  end

  it "should get all data_objects that came from an agents last harvest" do
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

    content_partner.resources.first.latest_harvest_event.
      data_objects.map {|ob| ob.id}.sort.should ==
      last_datos.map {|ob| ob.id}.sort
  end

  it "should know when it has resources that have unpublished content" do
    cp = ContentPartner.gen(user: user)
    
    # no resource means no content so we return false
    cp.unpublished_content?.should be_false 

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
    cp = ContentPartner.gen(user: user)
    ContentPartnerAgreement.gen(content_partner_id: cp.id, 
                                created_at: 4.hours.ago, 
                                updated_at: 4.hours.ago)
    ContentPartnerContact.gen(content_partner_id: cp.id, 
                              created_at: 3.hours.ago, 
                              updated_at: 3.hours.ago)
    Resource.gen(content_partner_id: cp.id, 
                 created_at: 2.hours.ago, updated_at: nil)
    last_action_date = Time.now
    Resource.gen(content_partner_id: cp.id, 
                 created_at: 1.hour.ago, updated_at: last_action_date)
    cp.reload
    cp.last_action_date.utc.strftime("%Y-%m-%d %H:%M:%S").
      should == last_action_date.utc.strftime("%Y-%m-%d %H:%M:%S")
  end

end
