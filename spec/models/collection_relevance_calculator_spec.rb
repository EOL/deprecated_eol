require "spec_helper"

# NOTE: this spec is incomplete... but I don't really care to complete it: the details of calculation have not really been discussed and are probably due to
# change, so I'm not going to get into those details.
#
# ...As a result, I'm stubbing some private methods on the class, here, in order to force calculations that I want.

describe CollectionRelevanceCalculator do

  before(:all) do
    SpecialCollection.create_enumerated
  end

  # NOTE - Don't do this in a let. It needs to be done BEFORE allow()s.
  before do
    @collection = Collection.gen
    @calculator = CollectionRelevanceCalculator.new(@collection)
  end

  before do
    allow(CollectionRelevanceCalculator).to receive(:new) { @calculator }
  end

  describe '.perform' do

    before do
      allow(@calculator).to receive(:set_relevance) { true }
    end

    it 'runs #set_relevance on an instance of the collection' do
      CollectionRelevanceCalculator.perform(@collection.id)
      expect(@calculator).to have_received(:set_relevance)
      expect(CollectionRelevanceCalculator).to have_received(:new).with(@collection)
    end

    it 'logs (info) the time that it is running' do
      time = Time.now
      allow(time).to receive(:strftime) { 'this is the strftime' }
      allow(Time).to receive(:now) { time }
      allow(Rails.logger).to receive(:error)
      CollectionRelevanceCalculator.perform(@collection.id)
      expect(Rails.logger).to have_received(:error).
        with(/this is the strftime/).at_least(:once)
    end

    it 'logs errors' do
      e = "THIS"
      allow(Rails.logger).to receive(:error)
      allow(@calculator).to receive(:set_relevance).and_raise(e)
      CollectionRelevanceCalculator.perform(@collection.id)
      expect(Rails.logger).to have_received(:error).with(/ERROR.*THIS/)
      expect(@calculator).to have_received(:set_relevance)
    end

  end

  before do
    allow(@collection).to receive(:watch_collection?) { false }
    allow(@collection).to receive(:taxa_count) { 1 }
    allow(@collection).to receive(:focus?) { false }
    # Yes, this conflicts with taxa_count, but let's ignore that for now.
    allow(@collection).to receive(:collection_items) { [] }
  end

  it 'uses notification queue' do
    expect(PrepareAndSendNotifications.class_eval { @queue }).to eq(:notifications)
  end

  it 'always ranks watch collections as 0' do
    @collection.should_receive(:watch_collection?).and_return(true)
    expect(@calculator.set_relevance).to eq(0)
  end

  it 'always ranks collections with no taxa as 0' do
    allow(@collection).to receive(:taxa_count) { 0 }
    expect(@calculator.set_relevance).to eq(0)
  end

  it 'skips updating attributes if calculation is 0' do
    allow(@calculator).to receive(:calculate_feature_relevance) { 0 }
    allow(@calculator).to receive(:calculate_taxa_relevance) { 0 }
    allow(@calculator).to receive(:calculate_item_relevance) { 0 }
    allow(@collection).to receive(:update_attributes) { true }
    expect(@calculator.set_relevance).to eq(0)
    expect(@collection).to_not have_received(:update_attributes)
  end

  it 'skips updating attributes if calculation is 100' do
    allow(@calculator).to receive(:calculate_feature_relevance) { 100 }
    allow(@calculator).to receive(:calculate_taxa_relevance) { 100 }
    allow(@calculator).to receive(:calculate_item_relevance) { 100 }
    allow(@collection).to receive(:update_attributes) { true }
    expect(@calculator.set_relevance).to eq(100)
    expect(@collection).to_not have_received(:update_attributes) # TODO - really?  Why not?
  end

  it 'updates attributes if calculation is 50' do
    allow(@calculator).to receive(:calculate_feature_relevance) { 50 }
    allow(@calculator).to receive(:calculate_taxa_relevance) { 50 }
    allow(@calculator).to receive(:calculate_item_relevance) { 50 }
    allow(@collection).to receive(:update_attributes) { true }
    @calculator.set_relevance
    expect(@collection).to have_received(:update_attributes).with(relevance: 50)
  end

end
