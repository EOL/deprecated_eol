require "spec_helper"

describe ItemPage do
  
  describe '.sort_by_title_year' do

    # NOTE - not going to check order, here, too complex.
    # ... just checking that these fields are all used for sort.
    it 'checks a bunch of fields' do
      item = ItemPage.new
      allow(item).to receive(:publication_title)
      allow(item).to receive(:year)
      allow(item).to receive(:volume)
      allow(item).to receive(:issue)
      allow(item).to receive(:number) { 1 }
      ItemPage.sort_by_title_year([item])
      expect(item).to have_received(:publication_title)
      expect(item).to have_received(:year)
      expect(item).to have_received(:volume)
      expect(item).to have_received(:issue)
      expect(item).to have_received(:number)
    end

  end

  describe '#display_string' do

    let(:item_page) { ItemPage.new(year: '', volume: '', issue: '') }

    it 'is blank when no info' do
      expect(item_page.display_string).to be_blank
    end

    it 'includes year' do
      allow(item_page).to receive(:year) { '1987' }
      expect(item_page.display_string).to match(/1987\./)
      expect(item_page.display_string).to_not match(/Vol/)
      expect(item_page.display_string).to_not match(/Issue/)
    end

    # TODO - Vol should be I18n'ed.
    it 'includes volume' do
      allow(item_page).to receive(:volume) { '12' }
      expect(item_page.display_string).to match(/Vol\.\s+12/)
      expect(item_page.display_string).to_not match(/Issue/)
    end

    # TODO - Issue should be I18n'ed.
    it 'includes issue' do
      allow(item_page).to receive(:issue) { '77' }
      expect(item_page.display_string).to match(/Issue\s+77/)
      expect(item_page.display_string).to_not match(/Vol/)
    end

  end

  describe "#publication_title" do

    # TODO - really, it shouldn't follow a CHAIN, but the next item
    # should follow the law of demeter itself. That would make this test
    # quite simple (as it should be). Here's a bad smell for test setup.
    it 'follows chain' do
      item = ItemPage.new
      pub_title = double("pub title", title: "Titular")
      title_item = double("title item", publication_title: pub_title)
      allow(item).to receive(:title_item) { title_item }
      expect(item.publication_title).to eq("Titular")
      expect(item).to have_received(:title_item)
      expect(title_item).to have_received(:publication_title)
      expect(pub_title).to have_received(:title)
    end

  end

  describe "#publication_id" do

    # NOTE - I don't actually consider *this* to be a violation of
    # Demeter's law, since it's "just an id", and I think it's safe
    # to assume an object "always" responds to :id.
    it 'gets id from title_item' do
      item = ItemPage.new
      pub_title = double("pub title", id: 8576)
      title_item = double("title item", publication_title: pub_title)
      allow(item).to receive(:title_item) { title_item }
      expect(item.publication_id).to eq(8576)
      expect(item).to have_received(:title_item)
      expect(title_item).to have_received(:publication_title)
      expect(pub_title).to have_received(:id)
    end

  end

  # TODO - really? Shouldn't this be an extension configured somewhere?
  it 'has a #page_url pointing to BHL' do
    expect(build(ItemPage, id: 1423).page_url).
      to eq("http://www.biodiversitylibrary.org/page/1423")
  end

  # TODO - really? Shouldn't this be an extension configured somewhere?
  it 'has a #publication_url pointing to BHL' do
    item = build(ItemPage)
    allow(item).to receive(:publication_id) { 5463 }
    expect(item.publication_url).
      to eq("http://www.biodiversitylibrary.org/title/5463")
  end

end

