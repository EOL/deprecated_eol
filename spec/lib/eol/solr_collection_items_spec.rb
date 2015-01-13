require File.dirname(__FILE__) + '/../../spec_helper'

describe EOL::Solr::CollectionItems do

  before(:all) do
    load_scenario_with_caching(:testy)
    @testy = EOL::TestInfo.load('testy')
    @collection = Collection.gen
    @collection.add @testy[:taxon_concept]
    EOL::Solr::CollectionItemsCoreRebuilder.reindex_collection_items_by_ids(@collection.collection_items.map {|i| i.id})
  end

  it '#should include the object we added' do
    results = @collection.items_from_solr
    results.map{|r| r['instance']}.compact.map(&:collected_item).include?(@testy[:taxon_concept]).should be_true
  end
  
  it "should update collection items count when reindex" do
    Collection.any_instance.should_receive(:update_attributes)
    EOL::Solr::CollectionItemsCoreRebuilder.reindex_collection(@collection)
  end

end
