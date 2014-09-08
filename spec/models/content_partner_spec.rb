# encoding: utf-8
# EXEMPLAR

describe ContentPartner do

  before(:all) do
    populate_tables(:contact_roles, :content_partner_statuses, :data_types,
                    :licenses)
  end

  let(:user) { create(:user) }
  subject { create(:content_partner, user: user, content_partner_status: nil) }

  it "has active status by default" do
    expect(subject.content_partner_status).to eq ContentPartnerStatus.active
  end

  it "responds to #logo_url" do
    expect(subject).to respond_to(:logo_url)
  end

  it "recalculates statistics when saved" do
    allow(EOL::GlobalStatistics).to receive(:clear)
    subject # Calling subject lazy-loads ContentPartner
    expect(EOL::GlobalStatistics).
      to have_received(:clear).with(:content_partners)
  end

  it "has no resources by default" do
    expect(subject.resources.empty?).to be true
  end

  context "when accessing someone else's content_partner" do
    let(:a_user) { create(:user) }

    it "is readable" do
      expect(subject.can_be_read_by?(a_user)).to be true
    end

    it "is NOT updatable" do
      expect(subject.can_be_updated_by?(a_user)).to be false
    end

    it "can NOT be created" do
      expect(subject.can_be_created_by?(a_user)).to be false
    end

    context "when content_partner is private" do
      subject do
        create(:content_partner, user: user, is_public: false)
      end

      it "is NOT readable" do
        expect(subject.can_be_read_by?(a_user)).to be false
      end
    end
  end

  context "when a user owns the content_partner" do
    it "is readable" do
      expect(subject.can_be_read_by?(user)).to be true
    end

    it "is updatable" do
      expect(subject.can_be_updated_by?(user)).to be true
    end

    it "can be created" do
      expect(subject.can_be_created_by?(user)).to be true
    end

    context "when the content_partner is private" do
      subject do
        create(:content_partner, user: user, is_public: false)
      end

      it "is readable" do
        expect(subject.can_be_read_by?(user)).to be true
      end
    end

  end

  describe "#unpublished_content?" do
    context "without resources" do
      it "is false" do
        expect(subject.unpublished_content?).to be false
      end
    end

    context "with one resource" do
      let!(:resource) { create(:resource, content_partner: subject) }

      context "without harvest events" do
        it "is true" do
          expect(subject.resources.first.harvest_events.empty?).to be true
          expect(subject.unpublished_content?).to be true
        end
      end

      context "with harvest events" do
        before do
          Rails.cache.clear
        end

        context "when the last event is unpublished" do
          let!(:event1) do
            create(:harvest_event, resource: resource, published_at: nil)
          end
          let!(:event2) do
            create(:harvest_event, resource: resource, published_at: nil)
          end

          it "is true" do
            expect(subject.resources.first.harvest_events.empty?).to be false
            expect(subject.unpublished_content?).to be true
          end
        end

        context "last event published" do
          let!(:event1) { create(:harvest_event, resource: resource) }
          let!(:event2) { create(:harvest_event, resource: resource) }

          it "is true" do
            expect(subject.resources.first.harvest_events.empty?).to be false
            expect(subject.unpublished_content?).to be false
          end
        end
      end
    end
  end

  describe "#latest_published_harvest_events" do
    let!(:resource1) { create(:resource, content_partner: subject) }
    let!(:resource2) { create(:resource, content_partner: subject) }
    let!(:event1) do
      create(:harvest_event, resource: resource1, published_at: 2.hours.ago)
    end
    let!(:event2) do
      create(:harvest_event, resource: resource1, published_at: 1.hours.ago)
    end
    let!(:event3) do
      create(:harvest_event, resource: resource2, published_at: 2.hours.ago)
    end
    let!(:event4) do
      create(:harvest_event, resource: resource2, published_at: 1.hours.ago)
    end

    it "returns array of latest published events" do
      res = subject.latest_published_harvest_events
      expect(res.to_set).to eq [event2, event4].to_set
    end
  end

  describe "#oldest_published_harvest_events" do
    let!(:resource1) { create(:resource, content_partner: subject) }
    let!(:resource2) { create(:resource, content_partner: subject) }
    let!(:event1) do
      create(:harvest_event, resource: resource1, published_at: 2.hours.ago)
    end
    let!(:event2) do
      create(:harvest_event, resource: resource1, published_at: 1.hours.ago)
    end
    let!(:event3) do
      create(:harvest_event, resource: resource2, published_at: 2.hours.ago)
    end
    let!(:event4) do
      create(:harvest_event, resource: resource2, published_at: 1.hours.ago)
    end

    it "returns array of oldest publiched events" do
      res = subject.oldest_published_harvest_events
      expect(res.to_set).to eq([event1, event3].to_set)
    end
  end

  describe "#primary_contact" do
    context "when it has no contacts" do
      it "returns nil" do
        expect(subject.primary_contact).to be nil
      end
    end

    context "when it has contacts" do
      let!(:contact1) do
        create(:content_partner_contact, content_partner: subject)
      end
      let!(:contact2) do
        create(:content_partner_contact, content_partner: subject)
      end
      it "returns one of the contacts" do
        expect(subject.primary_contact).to be_kind_of(ContentPartnerContact)
      end

      context "when it has a primary contact" do
        let!(:contact3) do
          create(:content_partner_contact,
                 content_partner: subject,
                 contact_role: ContactRole.primary)
        end
        it "returns primary contact" do
          expect(subject.primary_contact).to eq contact3
        end
      end
    end
  end

  describe "#last_action_date" do

    # We want to ensure the CP starts with nothing associated:
    subject { create(:content_partner) }

    let!(:latest_date) { 0.seconds.ago }
    let!(:other_date) { 2.hours.ago }
    let!(:contact) do
      create(:content_partner_contact,
             content_partner: subject,
             created_at: latest_date,
             updated_at: latest_date)
    end
    let!(:agreement) do
      create(:content_partner_agreement,
             content_partner: subject,
             created_at: other_date,
             created_at: other_date)
    end
    let!(:resource) do
      create(:resource,
             content_partner: subject,
             created_at: other_date,
             updated_at: other_date)
    end

    it "returns the last update_at or created_at date from several resources" do
      expect(subject.last_action_date.to_time).
        to be_within(0.5).of(latest_date.to_time)
    end
  end

  describe "#agreement" do
    let!(:invalid) do
      create(:content_partner_agreement,
             content_partner: subject,
             is_current: false,
             created_at: 0.minutes.ago)
    end
    let!(:recent_valid) do
      create(:content_partner_agreement,
             content_partner: subject,
             is_current: true,
             created_at: 2.minutes.ago)
    end
    let!(:old_valid) do
      create(:content_partner_agreement,
             content_partner: subject,
             is_current: true,
             created_at: 5.minutes.ago)
    end

    it "returns the lastest 'valid' agreement" do
      expect(subject.agreement).to eq recent_valid
    end
  end

  describe "#name" do

    context "when it does NOT have a display name" do
      subject { create(:content_partner, user: user, display_name: nil) }
      it "returns full name" do
        expect(subject.name).to eq subject.full_name
      end
    end

    context "when it has a display name" do
      subject do
        create(:content_partner, user: user, display_name: "Cool name")
      end
      it "returns display name" do
        expect(subject.name).to eq "Cool name"
      end
    end
  end

  describe "#collections" do
    # We want to ensure that it doesn't start with any associations:
    subject { create(:content_partner) }

    let!(:resource1) { create(:resource, content_partner: subject) }
    let!(:collection1) do
      create(:collection, resource: create(:resource, content_partner: subject))
    end
    let!(:collection2) do
      create(:collection, resource: create(:resource, content_partner: subject))
    end

    it "returns all collections for all resources" do
      expect(subject.collections.to_set).
        to eq([collection1, collection2].to_set)
    end
  end

end
