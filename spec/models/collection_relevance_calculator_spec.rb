require "spec_helper"

# NOTE: this spec is incomplete... but I don't really care to complete it: the details of calculation have not
# really been discussed and are probably due to change, so I'm not going to get into those details.

describe CollectionRelevanceCalculator do

  before(:all) do
    SpecialCollection.create_enumerated
  end

  let(:collection) { Collection.gen }
  let(:calculator) { CollectionRelevanceCalculator.new(collection) }

  describe '.perform' do

    it 'runs #set_relevance on an instance of the collection' do
      allow(CollectionRelevanceCalculator).to receive(:new) { collection }
      allow(collection).to receive(:set_relevance) { true }
      CollectionRelevanceCalculator.perform(collection.id)
      expect(collection).to have_received(:set_relevance)
      expect(CollectionRelevanceCalculator).to have_received(:new).with(collection)
    end

  end

  before do
    allow(collection).to receive(:watch_collection?) { false }
    allow(collection).to receive(:taxa_count) { 1 }
    allow(collection).to receive(:focus?) { false }
    # Yes, this conflicts with taxa_count, but let's ignore that for now.
    allow(collection).to receive(:collection_items) { [] }
  end

  it 'uses notification queue' do
    expect(PrepareAndSendNotifications.class_eval { @queue }).to eq(:notifications)
  end

  it 'always ranks watch collections as 0' do
    collection.should_receive(:watch_collection?).and_return(true)
    expect(calculator.set_relevance).to eq(0)
  end

  it 'always ranks collections with no taxa as 0' do
    collection.stub(:taxa_count).and_return(0)
    expect(calculator.set_relevance).to eq(0)
  end

  it 'skips updating attributes if calculation is 0' do
    allow(calculator).to receive(:calculate_feature_relevance) { 0 }
    allow(calculator).to receive(:calculate_taxa_relevance) { 0 }
    allow(calculator).to receive(:calculate_item_relevance) { 0 }
    allow(calculator).to receive(:update_attributes) { true }
    expect(calculator.set_relevance).to eq(0)
    expect(calculator).to_not have_received(:update_attributes)
  end

  it 'skips updating attributes if calculation is 100' do
    allow(calculator).to receive(:calculate_feature_relevance) { 100 }
    allow(calculator).to receive(:calculate_taxa_relevance) { 100 }
    allow(calculator).to receive(:calculate_item_relevance) { 100 }
    allow(calculator).to receive(:update_attributes) { true }
    expect(calculator.set_relevance).to eq(100)
    expect(calculator).to_not have_received(:update_attributes) # TODO - really?  Why not?
  end

end
