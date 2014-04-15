require "spec_helper"

describe TocItem do

  before(:all) do
    Visibility.create_enumerated
  end

  it 'should allow user submitted text' do
    toc_item = TocItem.gen(info_items: [InfoItem.gen])
    toc_item.allow_user_text?.should be_true
  end

  it 'should not allow user submitted text' do
    toc_item = TocItem.gen
    toc_item.allow_user_text?.should be_false
  end

  describe 'toc_object_counts' do

    before do
      allow(TocItem).to receive(:count_objects) { 37 }
    end

    it 'calls count_objects and caches it' do
      TocItem.toc_object_counts
      TocItem.toc_object_counts
      expect(TocItem).to have_received(:count_objects).once
    end

  end

  # TODO - this is almost raw SQL, so it's too painful to test. Only the most
  # basic stuff, here, to at least jog the code:
  # ...But if you were going to re-write the code, you should really create
  # a host of data_objects linked to several toc_items of various visibilities
  # and counts, and then test that.
  describe '.count_objects' do

    before do
      allow(TocItem.connection).to receive(:select_rows) do
        # NOTE strings, not ints; want to test that gets corrected.
        {'1' => '5',
         '2' => '4',
         '3' => '3'}
      end
    end

    it 'looks for visible objects' do
      allow(Visibility).to receive(:visible) { build_stubbed(Visibility) }
      TocItem.count_objects
      expect(Visibility).to have_received(:visible)
    end

    it 'returns hash of IDs and counts' do
      counts = TocItem.count_objects
      expect(counts[1]).to eq(5)
      expect(counts[2]).to eq(4)
      expect(counts[3]).to eq(3)
    end

  end

  describe 'enumerated class methods' do

    {
      bhl: 'Biodiversity Heritage Library',
      content_partners: 'Content Partners',
      name_and_taxonomy: 'Names and Taxonomy',
      related_names: 'Related Names'
    }.each do |method, string|
      it "uses #cached_find_translated on #{method}" do
        allow(TocItem).to receive(:cached_find_translated) { "foo" }
        expect(TocItem.send(method)).to eq("foo")
        expect(TocItem).to have_received(:cached_find_translated) do |field, string, includes|
          expect(field).to eq(:label)
          expect(string).to eq(string)
          # NOTE - don't much care about includes.
        end
      end
    end

  end

end
