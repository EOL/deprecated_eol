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
        @querystring = "foo"
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
        TaxonData.stub(:is_clade_searchable?).and_return(true)
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
        @taxon_concept.stub(:title_canonical_italicized).and_return('bear')
        search_file = build_stubbed(DataSearchFile, q: "queried", taxon_concept: @taxon_concept, from: 245, to: 489, completed_at: 2.seconds.ago, row_count: 10347)
        search_file.stub(:from_as_data_point).and_return(245) # BAD SMELL.  :|  TODO
        search_file.stub(:to_as_data_point).and_return(489) # BAD SMELL.  :|  TODO
        helper.stub(:display_text_for_data_point_uri).with(245).and_return(245) # BAD SMELL.  :|  TODO
        helper.stub(:display_text_for_data_point_uri).with(489).and_return(489) # BAD SMELL.  :|  TODO
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
