require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionItem do

  before(:all) do
    # so this part of the before :all runs only once
    unless User.find_by_username('collections_scenario')
      truncate_all_tables
      load_scenario_with_caching(:collections)
    end
    @collection = Collection.gen
    @taxon_concept = TaxonConcept.last
    SortStyle.create_defaults
  end

  it 'should add/modify/remove an annotation' do
    annotation = "Valid annotation"
    @collection.add(@taxon_concept)

    @collection.collection_items.last.annotation = annotation
    CollectionItem.last.annotation == annotation

    @collection.collection_items.last.annotation = "modified #{annotation}"
    CollectionItem.last.annotation == "modified #{annotation}"

    @collection.collection_items.last.annotation = ""
    CollectionItem.last.annotation.should be_blank
  end

  it 'should be able to sort collection items by newest/oldest' do
    collection = Collection.gen
    CollectionItem.gen(:collection => collection, :object => User.gen, :created_at => 2.seconds.ago)
    CollectionItem.gen(:collection => collection, :object => User.gen, :created_at => 1.seconds.ago)

    new_sort = CollectionItem.custom_sort(collection.collection_items, SortStyle.newest)
    new_sort[0].created_at.should > new_sort[1].created_at

    new_sort = CollectionItem.custom_sort(new_sort, SortStyle.oldest)
    new_sort[0].created_at.should < new_sort[1].created_at
  end

end
