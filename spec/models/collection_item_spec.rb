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
    @collection.add(User.gen) # add a collection_item of type User
    @collection.add(User.gen) # add another collection_item of type User
    @collection.collection_items[0].id.should < @collection.collection_items[1].id

    new_sort = CollectionItem.custom_sort(@collection.collection_items, 'newest')
    new_sort[0].id.should > new_sort[1].id

    new_sort = CollectionItem.custom_sort(new_sort, 'oldest')
    new_sort[0].id.should < new_sort[1].id
  end

end
