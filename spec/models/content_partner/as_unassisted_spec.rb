# encoding: utf-8

describe ContentPartner::AsUnassisted do
  before(:all) { populate_tables(:content_partner_statuses) }
  subject { build(:content_partner__as_unassisted) }

  describe ".new" do

    it "creates an instance of the class" do
      expect(subject).to be_kind_of ContentPartner
    end
  end 

  describe "#save" do
    it "deliver the content_partner_created message" do
      notifier = double(Notifier)
      allow(notifier).to receive(:deliver)
      allow(Notifier).to receive(:content_partner_created) { notifier }
      subject.save
      expect(Notifier).to have_received(:content_partner_created)
      expect(notifier).to have_received(:deliver)
    end
  end
end
