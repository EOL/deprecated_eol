require "spec_helper"

describe DataSearchHelper do

  describe '#data_search_results_summary' do

    context 'with nil @results' do

      before do
        @results = nil
      end

      it 'returns an empty string' do
        expect(helper.data_search_results_summary).to eq("")
      end

    end

    context 'with results for "foo" and no filter' do

      before do
        @results = double(Array, total_entries: 3)
        @attribute_known_uri = nil
        @attributes = "foo"
        @taxon_concept = nil
      end

      it 'counts results' do
        expect(helper.data_search_results_summary).to include(I18n.t(:count_results_for_search_term,
                                                            count: 3, search_term: "foo"))
      end

    end

    context 'with results for "foo" and a taxon filter' do

      before do
        @results = double(Array, total_entries: 3)
        @attribute_known_uri = nil
        @querystring = "foo"
        @taxon_concept = double(TaxonConcept, title_canonical_italicized: "rawr")
      end

      it 'reminds us it\'s searching in a clade' do
        expect(helper.data_search_results_summary).to include(I18n.t(:searching_within_clade,
          clade_name: link_to("rawr", taxon_overview_url(@taxon_concept))))
      end

    end

  end

  describe '#data_search_file_summary' do

    context "when everything is empty" do

      let(:summary) do
        search_file = double(DataSearchFile, q: "", taxon_concept: nil, from: nil, to: nil, complete?: false)
        helper.data_search_file_summary(search_file)
      end

      it 'returns an empty array' do
        expect(summary).to be_empty
      end

    end

    context "when everything is there" do

      let(:summary) do
        @taxon_concept = build_stubbed(TaxonConcept)
        allow(@taxon_concept).to receive(:title_canonical_italicized) { 'bear' }
        search_file = build_stubbed(DataSearchFile, q: "queried", taxon_concept: @taxon_concept, from: 245, to: 489, completed_at: 2.seconds.ago, row_count: 10347)
        allow(helper).to receive(:display_text_for_data_point_uri).with(245) { 245 } # - BAD SMELL
        allow(helper).to receive(:display_text_for_data_point_uri).with(489) { 489 } # - BAD SMELL
        helper.data_search_file_summary(search_file).join(" ") # Just need to check things as a string; don't much care about the array here.
      end

      it 'labels the query' do
        expect(summary).to include(I18n.t('helpers.label.data_search.q_with_val', val: "queried"))
      end

      it 'labels the taxon' do
        expect(summary).to include('bear')
        expect(summary).to include(taxon_overview_url(@taxon_concept))
      end

      it 'labels the from' do
        expect(summary).to include(I18n.t('helpers.label.data_search.min_with_val', val: 245))
      end

      it 'labels the to' do
        expect(summary).to include(I18n.t('helpers.label.data_search.max_with_val', val: 489))
      end

      it 'marks it as complete with delimited row count' do
        expect(summary).to include(I18n.t('helpers.label.data_search.total_results', total: "10,347"))
      end

    end

  end

end
