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

  context "someone else's content_partner" do
    let(:a_user) { User.gen }
    
    it "is readable" do
      expect(subject.can_be_read_by?(a_user)).to be true
    end

    it "is not updatable" do
      expect(subject.can_be_updated_by?(a_user)).to be false
    end

    it "is not creatable" do
      expect(subject.can_be_created_by?(a_user)).to be false
    end
    
    context "private content_partner" do
      subject do 
        ContentPartner.gen(user: user, is_public: false)
      end

      it "is not readable" do
        expect(subject.can_be_read_by?(a_user)).to be false
      end
    end
  end

  context "user owns content_partner" do
    it "is readable" do
      expect(subject.can_be_read_by?(user)).to be true
    end

    it "is not updatable" do
      expect(subject.can_be_updated_by?(user)).to be true 
    end

    it "is not creatable" do
      expect(subject.can_be_created_by?(user)).to be true
    end
    
    context "private content_partner" do
      subject do 
        ContentPartner.gen(user: user, is_public: false)
      end

      it "is not readable" do
        expect(subject.can_be_read_by?(user)).to be true
      end
    end
  end

  describe "#unpublished_content?" do
    context "no resources" do
      it "is false" do
        expect(subject.resources.empty?).to be true
        expect(subject.unpublished_content?).to be false
      end
    end

    context "with resource" do
      let!(:resource) { Resource.gen(content_partner: subject) }

      context "no harvest events" do
        it "is false" do
          expect(subject.resources.empty?).to be false
          expect(subject.resources.first.harvest_events.empty?).
            to be true
          expect(subject.unpublished_content?).to be true # wat?
        end
      end

      context "with harvest events" do

        context "last event unpublished" do 
          let!(:he1) do 
            HarvestEvent.gen(resource: resource, published_at: nil) 
          end 
          let!(:he2) do 
            HarvestEvent.gen(resource: resource, published_at: nil)
          end

          it "is true" do
            Rails.cache.clear
            expect(subject.resources.first.harvest_events.empty?).
              to be false
            expect(subject.unpublished_content?).to be true
          end
        end
        
        context "last event published" do 
          let!(:he1) { HarvestEvent.gen(resource: resource) }
          let!(:he2) { HarvestEvent.gen(resource: resource) }

          it "is true" do
            Rails.cache.clear
            expect(subject.resources.first.harvest_events.empty?).
              to be false
            expect(subject.unpublished_content?).to be false
          end
        end
      end
    end
  end

  describe "#latest_published_harvest_events" do 
    let!(:resource) { Resource.gen(content_partner: subject) }
    let!(:he1) { HarvestEvent.gen(resource: resource, 
                                  published_at: 2.hours.ago) }
    let!(:he2) { HarvestEvent.gen(resource: resource, 
                                  published_at: 1.hours.ago) }

    it "returns array of latest publiched events" do
      res = subject.latest_published_harvest_events
      expect(res).to be_kind_of Array
      expect(res.first).to eq he2
    end
  end

  describe "#oldest_published_harvest_events" do 
    let!(:resource) { Resource.gen(content_partner: subject) }
    let!(:he1) { HarvestEvent.gen(resource: resource, 
                                  published_at: 2.hours.ago) }
    let!(:he2) { HarvestEvent.gen(resource: resource, 
                                  published_at: 1.hours.ago) }

    it "returns array of oldest publiched events" do
      res = subject.oldest_published_harvest_events
      expect(res).to be_kind_of Array
      expect(res.first).to eq he1
    end
  end

  describe "#primary_contact" do
    context "no contacts" do
      it "returns nil" do
        expect(subject.primary_contact).to be nil
      end
    end

    context "has contacts" do
      let!(:contact1) { ContentPartnerContact.gen(content_partner: subject) }
      let!(:contact2) { ContentPartnerContact.gen(content_partner: subject) }
      it "returns first contact" do
        expect(subject.primary_contact).to eq contact1
      end

      context "has primary contact" do 
        let!(:contact3) do 
          ContentPartnerContact.gen(content_partner: subject,
                                    contact_role: ContactRole.primary )
        end
        it "returns primary contact" do
          expect(subject.primary_contact).to eq contact3
        end
      end
    end
  end

  describe "#last_action_date" do 
    let!(:latest_date) { 0.seconds.ago }
    let!(:other_date) { 2.hours.ago }
    let!(:contact) do 
      ContentPartnerContact.gen(content_partner: subject, 
                                created_at: latest_date,
                                updated_at: latest_date)
    end
    let!(:agreement) do
      ContentPartnerAgreement.gen(content_partner: subject,
                                  created_at: other_date,
                                  created_at: other_date)
    end
    let!(:record) do
      Resource.gen(content_partner: subject,
                 created_at: other_date,
                 updated_at: other_date)
    end

    it "returns the last update_at or create_at date from several resources" do
      expect(subject.last_action_date.to_s).to eq latest_date.to_s
    end
  end

  describe "#agreement" do
    let!(:agreement1) do
      ContentPartnerAgreement.gen(content_partner: subject,
                                  is_current:false,
                                  created_at: 0.minutes.ago)
    end
    let!(:agreement2) do
      ContentPartnerAgreement.gen(content_partner: subject,
                                  is_current: true,
                                  created_at: 2.minutes.ago)
    end
    let!(:agreement3) do
      ContentPartnerAgreement.gen(content_partner: subject,
                                  is_current: true,
                                  created_at: 5.minutes.ago)
    end

    
    it "returns the lastest 'valid' agreement" do
      expect(subject.agreement).to eq agreement2
    end
  end

  describe "#name" do
    
    context "there is no display name" do
      subject { ContentPartner.gen(user: user, display_name: nil) }
      it "returns full name" do
        expect(subject.name).to eq subject.full_name
      end
    end

    context "there is display name" do
      subject { ContentPartner.gen(user: user, display_name: "Cool name") }
      it "returns display name" do
        expect(subject.name).to eq "Cool name"
      end
    end
  end

  describe "#collection" do
    subject { ContentPartner.gen(user: user) }
    let!(:resource1) { Resource.gen(content_partner: subject)}
    let!(:resource2) do 
      r = Resource.gen(content_partner: subject)
      Collection.gen(resource: r) 
      r
    end
    let!(:resource3) do 
      r = Resource.gen(content_partner: subject)
      Collection.gen(resource: r) 
      r
    end
    it "returns all collections for all resources" do
      collections = subject.collections
      expect(collections.size).to eq 2
      expect(collections.select { |c| c.class == Collection }.size).to eq 2 
    end
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
