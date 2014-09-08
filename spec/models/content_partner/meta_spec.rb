# encoding: utf-8
# EXEMPLAR

describe ContentPartner::Meta do
  subject { ContentPartner::Meta.new }

  describe "#title" do
    it "returns translated title" do
      expect(subject.title).to eq I18n.t(:content_partners_page_title)
    end
  end

  describe "#subtitle" do
    it "returns translated subtitle" do
      expect(subject.subtitle).
        to eq I18n.t(:content_partner_new_page_subheader)
    end
  end
end
