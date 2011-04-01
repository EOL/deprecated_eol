require File.dirname(__FILE__) + '/../spec_helper'

describe 'Configuration' do
  before :all do
    truncate_all_tables
    load_foundation_cache
    
    @tiger_name = 'Tiger'
    @taxon_concept = build_taxon_concept(:common_names => [@tiger_name])
    
    recreate_solr_indexes
  end
  
  after :each do
    truncate_all_logging_tables
  end
  
  describe ' : DataLogging' do
    describe ' : disabled' do
      before :all do
        $OLD_LOGGING_VALUE = $ENABLE_DATA_LOGGING
        $ENABLE_DATA_LOGGING = false
      end
      after :all do
        $ENABLE_DATA_LOGGING = $OLD_LOGGING_VALUE
      end
      
      it 'should not generate any taxa page logs when logging is disabled' do
        visit("/pages/#{@taxon_concept.id}")
        PageViewLog.all.size.should == 0
      end
      
      it 'should not generate any search logs when logging is disabled' do
        visit("/search/?q=#{@tiger_name}")
        SearchLog.all.size.should == 0
      end
    end
    
    describe ' : enabled' do
      before :all do
        $OLD_LOGGING_VALUE = $ENABLE_DATA_LOGGING
        $ENABLE_DATA_LOGGING = true
      end
      after :all do
        $ENABLE_DATA_LOGGING = $OLD_LOGGING_VALUE
      end
      
      it 'should generate taxa page logs when logging is enabled' do
        visit("/pages/#{@taxon_concept.id}")
        PageViewLog.all.size.should > 0
      end
      
      it 'should generate search logs when logging is enabled' do
        visit("/search/?q=#{@tiger_name}")
        SearchLog.all.size.should > 0
      end
    end
    
  end
  
end

