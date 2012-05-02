require File.dirname(__FILE__) + '/../../spec_helper'

describe Collections::InaturalistsController do

  before(:all) do
    # so this part of the before :all runs only once
    unless User.find_by_username('collections_scenario')
      truncate_all_tables
      load_scenario_with_caching(:collections)
    end
    @test_data  = EOL::TestInfo.load('collections')
    @collection = @test_data[:collection]
    EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild
  end

  describe 'GET show' do
    it "should not show iNaturalists observations sub-tab if inaturalist project doesn't exist for the collection"
  end

end