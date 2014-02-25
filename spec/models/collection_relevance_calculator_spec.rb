require "spec_helper"

describe CollectionRelevanceCalculator do

  before(:all) do
    @taxon = TaxonConcept.gen
    @collection_item = CollectionItem.gen(collected_item: @taxon)
    @collection = Collection.gen
    @collection.collection_items = [@collection_item]
    @calculator = CollectionRelevanceCalculator.new(@collection)
  end

  it 'always ranks watch collections as 0' do
    @collection.should_receive(:watch_collection?).and_return(true)
    expect(@calculator.set_relevance).to eq(0)
  end

  it 'always ranks collections with no taxa as 0' do
    @collection.stub(:taxa_count).and_return(0)
    expect(@calculator.set_relevance).to eq(0)
  end

  it 'skips updating attributes if calculation is 0' do
    @calculator.should_receive(:calculate_feature_relevance).and_return(0)
    @calculator.should_receive(:calculate_taxa_relevance).and_return(0)
    @calculator.should_receive(:calculate_item_relevance).and_return(0)
    @calculator.should_not_receive(:update_attributes)
    expect(@calculator.set_relevance).to eq(0)
  end

  it 'skips updating attributes if calculation is 0' do
    @calculator.should_receive(:calculate_feature_relevance).and_return(100)
    @calculator.should_receive(:calculate_taxa_relevance).and_return(100)
    @calculator.should_receive(:calculate_item_relevance).and_return(100)
    @calculator.should_not_receive(:update_attributes)
    expect(@calculator.set_relevance).to eq(100)
  end

end
