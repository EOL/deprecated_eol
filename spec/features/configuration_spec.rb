require "spec_helper"

describe 'Configuration' do

  before :all do
    load_foundation_cache
    @tiger_name = 'Tiger'
    @taxon_concept = build_taxon_concept(common_names: [@tiger_name])
    SolrHelpers.recreate_solr_indexes
  end

  describe ' : DataLogging' do

    describe ' : disabled' do

      before :all do
        $OLD_LOGGING_VALUE = $ENABLE_DATA_LOGGING
        $ENABLE_DATA_LOGGING = false
        @page_view_log_size = PageViewLog.count
        @search_log_size = SearchLog.count
      end

      after :all do
        $ENABLE_DATA_LOGGING = $OLD_LOGGING_VALUE
      end

      it 'should not generate any taxa page logs when logging is disabled' do
        visit("/pages/#{@taxon_concept.id}")
        PageViewLog.count.should == @page_view_log_size
      end

      it 'should not generate any search logs when logging is disabled' do
        visit("/search/?q=#{@tiger_name}")
        SearchLog.count.should == @search_log_size
      end
    end

    describe ' : enabled' do

      before :all do
        $OLD_LOGGING_VALUE = $ENABLE_DATA_LOGGING
        $ENABLE_DATA_LOGGING = true
        @page_view_log_size = PageViewLog.count
        @search_log_size = SearchLog.count
      end

      after :all do
        $ENABLE_DATA_LOGGING = $OLD_LOGGING_VALUE
      end

      it 'should generate taxa page logs when logging is enabled' do
        visit("/pages/#{@taxon_concept.id}")
        PageViewLog.count.should > @page_view_log_size
      end

      it 'should generate search logs when logging is enabled' do
        visit("/search/?q=#{@tiger_name}")
        SearchLog.count.should > @search_log_size
      end

    end

  end

end
