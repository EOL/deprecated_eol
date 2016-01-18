require "spec_helper"

# NOTE - there are multiple expectations per spec, here.
# Sometimes this is because setup is "expensive" (in terms of
# Lines of code), but mostly this is because I don't think this
# class being tested is well-written, so I expect major changes.
# ...and I didn't want to write lots of convoluted specs if they
# would eventually change.

# Also: damn. There was a lot to spec here, and it seems a relatively
# insignificant class to necessitate such a large number of methods. :\

describe TocItem do

  before(:all) do
    Visibility.create_enumerated
    Language.create_english
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

    before(:all) do
      Visibility.create_enumerated
    end

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
      related_names: 'Related Names',
      page_statistics: 'Page Statistics',
      content_summary: 'Content Summary',
      overview: 'Overview',
      education_resources: 'Education Resources',
      identification_resources: 'Identification Resources',
      biomedical_terms: 'Biomedical Terms',
      literature_references: 'Literature References',
      nucleotide_sequences: 'Nucleotide Sequences',
      citizen_science: 'Citizen Science',
      citizen_science_links: 'Citizen Science links',
      wikipedia: 'Wikipedia',
      brief_summary: 'Brief Summary',
      comprehensive_description: 'Comprehensive Description',
      distribution: 'Distribution'
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

  describe 'named name and taxonomy children' do

    let(:name_and_taxonomy_id) { 543 }
    let(:name_and_taxonomy) { double(TocItem, id: name_and_taxonomy_id, label: 'Name and Taxonomy') }
    let(:synonyms) { double(TocItem, label: 'Synonyms') }
    let(:common_names) { double(TocItem, label: 'Common Names') }
    before do
      # Using double because translations makes build_stubbed too weird:
      allow(TocItem).to receive(:find_all_by_parent_id) { [synonyms, common_names] }
      allow(TocItem).to receive(:name_and_taxonomy) { name_and_taxonomy }
    end

    [:common_names, :synonyms].each do |method|
      it "##{method} finds children of name and taxonomy" do
        TocItem.send(method)
        expect(TocItem).to have_received(:find_all_by_parent_id) do |parent_id, includes|
          expect(parent).to eq(name_and_taxonomy_id)
          # Don't care about includes.
        end
      end
    end

    it '#synonyms returns synonyms' do
      ret_val = TocItem.synonyms
      expect(ret_val).to eq(synonyms)
    end

    it '#common_names returns common names' do
      ret_val = TocItem.common_names
      expect(ret_val).to eq(common_names)
    end

  end

  describe '.find_by_en_label' do

    it 'uses #cached_find_translated with appropriate args' do
      allow(TocItem).to receive(:cached_find_translated) { "results" }
      expect(TocItem.find_by_en_label(:whatever)).to eq("results")
      expect(TocItem).to have_received(:cached_find_translated) do |field, name, includes|
        expect(field).to eq(:label)
        expect(name).to eq(:whatever)
        expect(includes).to include(:info_items)
        expect(includes).to include({ parent: :info_items })
      end
    end

  end

  describe '.possible_overview_ids' do

    it 'Gets ids from overview items' do
      allow(TocItem).to receive(:brief_summary) { double(TocItem, id: 5) }
      allow(TocItem).to receive(:comprehensive_description) { double(TocItem, id: 67) }
      allow(TocItem).to receive(:distribution) { double(TocItem, id: 999) }
      expect(TocItem.possible_overview_ids).to eq([5, 67, 999])
      expect(TocItem).to have_received(:brief_summary)
      expect(TocItem).to have_received(:comprehensive_description)
      expect(TocItem).to have_received(:distribution)
    end

  end

  describe '.education_chapters' do

    it 'uses #cached_find_translated on EN to get all Education items' do
      allow(TocItem).to receive(:cached_find_translated) { "happy-happy" }
      expect(TocItem.education_chapters).to eq("happy-happy")
      expect(TocItem).to have_received(:cached_find_translated) do |field, name, lang, options|
        expect(field).to eq(:label)
        expect(name).to eq('Education')
        expect(lang).to eq('en')
        expect(options).to eq(find_all: true)
      end
    end

  end

  describe '.education_for_resources_tab' do

    it 'includes education chapters and education resources' do
      allow(TocItem).to receive(:education_chapters) { ["this", "and"] }
      allow(TocItem).to receive(:education_resources) { "that" }
      expect(TocItem.education_for_resources_tab).to eq(%w{this and that})
    end

  end

  describe '.exclude_from_details' do

    # NOTE - while this is long, it's actually kind of neat what it's doing...
    it "excludes list of items using #cached_find_translated" do
      # Given a list of expected strings,
      items = [
        "Education", "Education Resources", "High School Lab Series",
        "Identification Resources", "Search the Web",
        "Literature References", "Biodiversity Heritage Library", "Bibliographies",
        "Bibliography", "Biomedical Terms", "On the Web",
        "Related Names", "Synonyms", "Common Names",
        "Content Summary", "Content Partners",
        "Citizen Science", "Citizen Science links"
      ]
      # Catch calls to this method:
      allow(TocItem).to receive(:cached_find_translated)
      # Run the method:
      TocItem.exclude_from_details
      # Then, for each item:
      items.each do
        # Expect it to have received the method (note the "exactly...times"
        # works when used in a loop):
        expect(TocItem).to have_received(:cached_find_translated).
          exactly(items.length).times do |field, name, lang, args|
          # And (for each item), expect the field to be label every time,
          expect(field).to eq(:label)
          # And the name to be in our list of expected strings each time,
          expect(items).to include(name)
          # And the same lang every time,
          expect(lang).to eq('en')
          # ...and always returning an array:
          expect(args).to eq(find_all: true)
        end
      end
      # NOTE - I'm only commenting every line here 'cause it's an unusal spec,
      # which I actually feel moderately happy with (though I feel the list of
      # strings should be configured, not hard-coded), so we could copy the
      # pattern with other specs, potentially.
    end

  end

  describe '.last_major_chapter' do

    before(:all) do
      TocItem.delete_all
      @one = TocItem.gen(parent_id: 0, view_order: 1)
      @two = TocItem.gen(parent_id: 0, view_order: 2)
      @three = TocItem.gen(parent_id: 0, view_order: 3)
    end

    it 'finds the latest' do
      expect(TocItem.last_major_chapter).to eq(@three)
    end

  end

  # TODO - this smells bad. I can't put my finger on why. Refactor.
  describe '.swap_entries' do

    before do
      TocItem.delete_all
      @major_1 = TocItem.gen(parent_id: 0, view_order: 1)
      @minor_1_2 = TocItem.gen(parent_id: @major_1.id, view_order: 2)
      @minor_1_3 = TocItem.gen(parent_id: @major_1.id, view_order: 3)
      @major_4 = TocItem.gen(parent_id: 0, view_order: 4)
      @minor_4_5 = TocItem.gen(parent_id: @major_4.id, view_order: 5)
      @minor_4_6 = TocItem.gen(parent_id: @major_4.id, view_order: 6)
    end

    def check_order
      expect(@major_1.reload.view_order).to eq(1)
      expect(@minor_1_2.reload.view_order).to eq(2)
      expect(@minor_1_3.reload.view_order).to eq(3)
      expect(@major_4.reload.view_order).to eq(4)
      expect(@minor_4_5.reload.view_order).to eq(5)
      expect(@minor_4_6.reload.view_order).to eq(6)
    end

    # NOTE - if this spec fails, fix it first; it's a problem with SPECS,
    # not the model, and this needs to work before the other specs work.
    it '#check_order spec helper works' do
      check_order
    end

    it 'only works on two TocItems' do
      expect(TocItem.swap_entries("this", "that")).to be_nil
      check_order
      expect(TocItem.swap_entries("this", @major_1)).to be_nil
      check_order
      expect(TocItem.swap_entries(@major_1, "that")).to be_nil
      check_order
    end

    it 'works when both items are major, fixes minors' do
      TocItem.swap_entries(@major_1, @major_4)
      expect(@major_1.reload.view_order).to eq(4)
      expect(@minor_1_2.reload.view_order).to eq(5)
      expect(@minor_1_3.reload.view_order).to eq(6)
      expect(@major_4.reload.view_order).to eq(1)
      expect(@minor_4_5.reload.view_order).to eq(2)
      expect(@minor_4_6.reload.view_order).to eq(3)
    end

    it 'works when both items are minor' do
      TocItem.swap_entries(@minor_1_2, @minor_1_3)
      expect(@minor_1_2.reload.view_order).to eq(3)
      expect(@minor_1_3.reload.view_order).to eq(2)
    end

    it 'does NOT work when one is major, other minor' do
      expect(TocItem.swap_entries(@major_1, @minor_1_3)).to be_nil
      check_order
    end

    it 'also works if second major is higher on list' do
      TocItem.swap_entries(@major_4, @major_1)
      expect(@major_1.reload.view_order).to eq(4)
      expect(@major_4.reload.view_order).to eq(1)
    end

  end

  describe '.selectable_toc' do

    let(:toc_item_1) { build_stubbed(TocItem) }
    let(:toc_item_2) { build_stubbed(TocItem) }
    let(:toc_item_3) { build_stubbed(TocItem) }

    before do
      allow(TocItem).to receive(:find) { [toc_item_1, toc_item_2] }
      allow(toc_item_1).to receive(:allow_user_text?) { true }
      allow(toc_item_2).to receive(:allow_user_text?) { true }
      allow(toc_item_3).to receive(:allow_user_text?) { false }
      allow(toc_item_1).to receive(:label) { "bbb" }
      allow(toc_item_2).to receive(:label) { "aaa" }
      allow(toc_item_3).to receive(:label) { "ab" }
    end

    it 'checks allow_user_text? on results' do
      TocItem.selectable_toc
      expect(toc_item_1).to have_received(:allow_user_text?)
      expect(toc_item_2).to have_received(:allow_user_text?)
    end

    it 'looks for all toc items (with info items)' do
      TocItem.selectable_toc
      expect(TocItem).to have_received(:find).with(:all, include: :info_items)
    end

    it 'sorts results' do
      expect(TocItem.selectable_toc).to eq([toc_item_2, toc_item_1])
    end

  end

  describe '.roots' do

    before do
      TocItem.delete_all
      @toc_2 = TocItem.gen(parent_id: 0, view_order: 2)
      @toc_1 = TocItem.gen(parent_id: 0, view_order: 1)
      @toc_child_3 = TocItem.gen(parent_id: 1, view_order: 3)
    end

    it 'finds roots, not children, by view order' do
      expect(TocItem.roots).to eq([@toc_1, @toc_2])
    end

  end

  describe '.whole_tree' do

    before do
      TocItem.delete_all
      @toc_2 = TocItem.gen(parent_id: 0, view_order: 2)
      @toc_1 = TocItem.gen(parent_id: 0, view_order: 1)
      @toc_child_3 = TocItem.gen(parent_id: 1, view_order: 3)
    end

    it 'find everything, by view order' do
      expect(TocItem.whole_tree).to eq([@toc_1, @toc_2, @toc_child_3])
    end

  end

  describe '.add_major_chapter' do

    before do
      TocItem.delete_all
    end

    it 'does nothing without label' do
      TocItem.add_major_chapter('')
      expect(TocItem.count).to eq(0)
    end

    it 'finds the next-highest view order' do
      TocItem.gen(view_order: 35)
      TocItem.add_major_chapter('foo')
      expect(TocItem.last.view_order).to eq(36)
    end

    it 'sets parent_id to 0' do
      TocItem.add_major_chapter('foo')
      expect(TocItem.last.parent_id).to eq(0)
    end

    # NOTE: disabling this, since it's VERY rarely used and needs cache refresh due to i18n.
    # it 'creates translated label in English' do
    #   TocItem.add_major_chapter('foo')
    #   expect(TocItem.last.label).to eq('foo')
    #   expect(TranslatedTocItem.last.label).to eq('foo')
    #   expect(TranslatedTocItem.last.language).to eq(Language.english)
    # end

  end

  describe '.toc_for_data_objects' do

    let(:toc_a) { TocItem.gen(parent_id: 0) }
    let(:toc_b) { TocItem.gen(parent_id: 0) }
    let(:toc_c) { TocItem.gen(parent: toc_a) }

    let(:object_with_toc_a) { build_stubbed(DataObject, toc_items: [toc_a]) }
    let(:object_with_toc_a_and_b) { build_stubbed(DataObject, toc_items: [toc_a, toc_b]) }
    let(:object_with_toc_c) { build_stubbed(DataObject, toc_items: [toc_c]) }
    let(:object_with_toc_none) { build_stubbed(DataObject, toc_items: []) }

    before do
      allow(DataObject).to receive(:preload_associations)
    end

    it 'preloads the objects' do
      TocItem.toc_for_data_objects([object_with_toc_a])
      # Let's not dictate HOW it's called, just that it is:
      expect(DataObject).to have_received(:preload_associations)
    end

    it 'skips data objects with no toc_item' do
      expect(TocItem.toc_for_data_objects([object_with_toc_none])).to eq([])
    end

    it 'adds parents' do
      expect(TocItem.toc_for_data_objects([object_with_toc_c]))
        .to include(toc_a)
    end

    it 'has no duplicates' do
      expect(TocItem.toc_for_data_objects([object_with_toc_a,
                                           object_with_toc_a_and_b])).
        to eq([toc_a, toc_b])
    end

    it 'sorts by view_order' do
      expect(TocItem.toc_for_data_objects([object_with_toc_c,
                                           object_with_toc_a])).
        to eq([toc_a, toc_c])
    end

  end

  describe '.for_uris' do

    let(:lang) { Language.english }

    before do
      allow(TocItem).to receive(:cached_find_translated) { [double(TocItem)] }
      # NOTE - since we're testing it several times, we have to remove the cache:
      if TocItem.instance_variable_defined?("@for_uris")
        TocItem.instance_eval { remove_instance_variable "@for_uris" }
      end
    end

    # NOTE - because some of the results could be arrays, like education
    it 'compacts results' do
      allow(TocItem).to receive(:cached_find_translated) do
        [double(TocItem), nil]
      end
      expect(TocItem.for_uris(lang)).to_not include(nil)
    end

    it 'looks up all labels in FOR_URIS' do
      TocItem.for_uris(lang)
      TocItem::FOR_URIS.each do |item|
        expect(TocItem).to have_received(:cached_find_translated).
          exactly(TocItem::FOR_URIS.length).times do |field, name, language|
          expect(TocItem::FOR_URIS).to include(name)
        end
      end
    end

    it 'looks up labels by language' do
      TocItem.for_uris(lang)
      expect(TocItem).to have_received(:cached_find_translated).
        at_least(:once) do |field, name, language|
        expect(language).to eq(lang.iso_code)
      end
    end

    it 'looks up labels by iso code' do
      TocItem.for_uris(lang.iso_code)
      expect(TocItem).to have_received(:cached_find_translated).
        at_least(:once) do |field, name, language|
        expect(language).to eq(lang.iso_code)
      end
    end

  end

  describe '.used_by_known_uris' do

    before do
      TocItem.delete_all
      # NOTE - reverse create order to view order
      @toc_3 = TocItem.gen(view_order: 3)
      @toc_2 = TocItem.gen(view_order: 2)
      @toc_1 = TocItem.gen(view_order: 1)
      @known_uri_1 = KnownUri.gen(toc_items: [@toc_1])
      @known_uri_3 = KnownUri.gen(toc_items: [@toc_3])
      @known_uri_3a = KnownUri.gen(toc_items: [@toc_3])
    end

    subject { TocItem.used_by_known_uris }

    it { should_not include(@toc_2) }

    it 'orders by view order, with no duplicates' do
      expect(subject).to eq([@toc_1, @toc_3])
    end

  end

end
