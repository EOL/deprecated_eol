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
    SortStyle.create_enumerated
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
  
  # TODO - change here to use Solr or leave that to the collection integration spec?
  it 'should be able to sort collection items by newest/oldest'

end
