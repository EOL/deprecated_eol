require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonSummary do

  def bootstrap(tc)
    tc.stub(:entry).and_return(@entry)
    tc.stub(:collected_name).and_return('hi there')
    tc.stub(:published_exemplar_image).and_return(@image)
    tc.stub(:preferred_classification_summary).and_return('King > Parent')
    tc.stub(:preferred_common_name_in_language).with(Language.default).and_return(@common_name)
  end

  before(:all) do
    DataType.create_enumerated
    MimeType.create_enumerated
    Language.create_english
    License.create_enumerated
    rank = Rank.gen
    @entry = HierarchyEntry.gen(rank: rank)
    @image = DataObject.gen
    @taxon_concept = TaxonConcept.gen
    @common_name = 'Frubblin dibbleborf'
  end

  # NOTE - since we stub, this can't be a before(:all)
  before do
    bootstrap(@taxon_concept)
  end
  
  context '#populate' do

    it 'should yank all the info from a taxon_concept to populate its fields' do
      summary = TaxonSummary.populate(@taxon_concept)
      expect(summary.taxon_concept).to eq(@taxon_concept)
      expect(summary.entry).to eq(@taxon_concept.entry)
      expect(summary.scientific_name).to eq(@taxon_concept.collected_name)
      expect(summary.rank).to eq(@taxon_concept.entry.rank)
      expect(summary.image).to eq(@taxon_concept.published_exemplar_image)
      expect(summary.default_common_name).to eq(@taxon_concept.preferred_common_name_in_language(Language.default))
    end

    it 'should overwrite old summaries' do
      summary = TaxonSummary.populate(@taxon_concept)
      @taxon_concept.should_receive(:preferred_classification_summary).and_return("Tweedle-dee")
      summary = TaxonSummary.populate(@taxon_concept)
      expect(summary.classification_summary).to eq("Tweedle-dee")
    end

  end

  it 'should always believe it has a preferred_classification_summary' do
    summary = TaxonSummary.populate(@taxon_concept)
    expect(summary.preferred_classification_summary?).to be_true
  end

  it 'should read table for default common name' do
    summary = TaxonSummary.populate(@taxon_concept)
    expect(summary.default_common_name).to eq(@common_name)
  end

  it 'should defer to the taxon concept for other common names' do
    new_lang = Language.gen
    @taxon_concept.should_receive(:preferred_common_name_in_language).with(new_lang).and_return("Hello kitty")
    summary = TaxonSummary.populate(@taxon_concept)
    expect(summary.preferred_common_name_in_language(new_lang)).to eq("Hello kitty")
  end

end
