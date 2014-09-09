# encoding: utf-8

describe ContentPartner::IndexMeta do
  let(:params) do
    { name: "MightyPartner", sort_by: "newest", page: 2 }
  end
  let(:cms_url) { "/cms_url" }
  subject { ContentPartner::IndexMeta.new(params, cms_url) }

  describe ".new" do
    it "creates instance" do
      expect(subject).to be_kind_of ContentPartner::IndexMeta
    end
  end

  describe "#name" do
    context "without name parameter" do
      let(:params) { {} }
      it "returns empty string" do
        expect(subject.name).to eq ""
      end
    end

    context "with name parameter" do
      it "returns name" do
        expect(subject.name).to eq "MightyPartner"
      end
    end
  end

  describe "#sort_by" do 
    context "without sort_by parameter" do
      let(:params) { {} }
      it "returns 'partner' string" do
        expect(subject.sort_by).to eq "partner"
      end
    end

    context "with sort_by parameter" do 
      it "returns params sort_by value" do 
        expect(subject.sort_by).to eq "newest"
      end
    end
  end

  describe "#page" do 
    context "without page parameter" do
      let(:params) { {} }
      it "returns nil" do 
        expect(subject.page).to be nil
      end
    end

    context "with page parameter" do 
      it "returns params page value" do 
        expect(subject.page).to eq 2 
      end
    end
  end

  describe "#title" do
    it "returns title from translation" do 
      expect(subject.title).to eq I18n.t(:content_partners_page_title)
    end
  end

  describe "#description" do 
    it "returns description from translation" do 
      expect(subject.description).
        to eq I18n.t(:content_partners_page_description, more_url: cms_url)
    end
  end

  describe "#sort_options" do
    it "returns sort options from translation" do
      expect(subject.sort_options).
        to include [I18n.t(:content_partner_column_header_partner), "partner"]
    end
  end
end
