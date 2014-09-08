# encoding: utf-8
# EXEMPLAR

describe ContentPartner::Pagination do
  subject { ContentPartner::Pagination }
  let(:params) do
    { name: "MightyPartner", sort_by: "oldest", page: 1 }
  end
  let(:cms_url) { "/cms_url" }
  let(:index_meta) { ContentPartner::IndexMeta.new(params, cms_url) }

  describe ".paginate" do
    
    it "creates paginate data for paginator gem" do
      data = { 
        page: 1,
        per_page: 10,
        select: subject::SELECT_ITEMS,
        include: subject::INCLUDE,
        conditions: [subject::CONDITIONS, { name: "%MightyPartner%" }],
        order: "content_partners.created_at"
      }
      allow(ContentPartner).to receive(:paginate)
      subject.paginate(index_meta) 
      expect(ContentPartner).to have_received(:paginate).with(data)
    end
  end
end
