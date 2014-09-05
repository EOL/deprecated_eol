# encoding: utf-8

describe ContentPartner::IndexMeta do
  let(:params) do
    { name: "MightyPartner", sort_by: "name", page: 1, }
  end
  let(:cms_url) { "/cms_url" }
  subject { ContentPartner::IndexMeta.new(params, cms_url) }

  describe ".new" do
    subject { ContentPartner::IndexMeta }

    it "creates instance" do
      im = subject.new(params, cms_url) 
      expect(im).to be_kind_of subject
      expect(im.name).to eq params[:name]
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
        expect(subject.sort_by).to eq "name"
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
        expect(subject.page).to eq 1
      end
    end
  end

  describe "#title" do
    it "returns title from translation" do 
      expect(subject.title).to eq "Content Partners"
    end
  end

  describe "#description" do 
    it "returns description from translation" do 
      expect(subject.description).to match("Encyclopedia of Life content")
      expect(subject.description).to match(/"\/cms_url">/)
    end
  end

  describe "#sort_options" do
    it "returns sort options from translation" do
      expect(subject.sort_options).to be_kind_of Array
      expect(subject.sort_options.first).to eq ["Partner", "partner"]
    end
  end
end
