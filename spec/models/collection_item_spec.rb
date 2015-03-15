require "spec_helper"

describe CollectionItem do

  before(:all) do
    # so this part of the before :all runs only once
    unless User.find_by_username('collections_scenario')
      truncate_all_tables
      load_foundation_cache
    end
    @collection = Collection.first
    @taxon_concept = TaxonConcept.last
    SortStyle.create_enumerated
    @collection.add(@taxon_concept)
  end

  it 'should add/modify/remove an annotation' do
    annotation = "Valid annotation"

    @collection.collection_items.last.annotation = annotation
    CollectionItem.last.annotation == annotation

    @collection.collection_items.last.annotation = "modified #{annotation}"
    CollectionItem.last.annotation == "modified #{annotation}"

    @collection.collection_items.last.annotation = ""
    CollectionItem.last.annotation.should be_blank
  end
  
  # TODO - change here to use Solr or leave that to the collection feature spec?
  it 'should be able to sort collection items by newest/oldest'

  it "tells if item is hidden or not" do
    expect(@collection.collection_items.last.is_hidden?).to be_false
  end
end
