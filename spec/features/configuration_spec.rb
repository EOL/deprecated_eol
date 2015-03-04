require "spec_helper"

describe 'Configuration' do

  before :all do
    load_foundation_cache
    @tiger_name = 'Tiger'
    @taxon_concept = build_taxon_concept(common_names: [@tiger_name],
                                         comments: [], bhl: [], toc: [], sounds: [], images: [], youtube: [], flash: [])
    SolrHelpers.recreate_solr_indexes
  end

  describe ' : DataLogging' do

    describe ' : disabled' do

      before :all do
        $OLD_LOGGING_VALUE = $ENABLE_DATA_LOGGING
        $ENABLE_DATA_LOGGING = false
        @search_log_size = SearchLog.count
      end

      after :all do
        $ENABLE_DATA_LOGGING = $OLD_LOGGING_VALUE
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
        @search_log_size = SearchLog.count
      end

      after :all do
        $ENABLE_DATA_LOGGING = $OLD_LOGGING_VALUE
      end

      it 'should generate search logs when logging is enabled' do
        visit("/search/?q=#{@tiger_name}")
        SearchLog.count.should > @search_log_size
      end

    end

  end

end
