require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonConceptReindexing do

  before(:all) do
    @taxon_concept = TaxonConcept.gen # Doesn't need to be anything fancy, here.
    @max_descendants = 10
  end

  before(:each) do
    EOL::Config.stub!(:max_curatable_descendants).and_return(@max_descendants)
    TaxonClassificationsLock.delete_all
  end

  it 'should raise an error if locked' do
    lambda {
      @taxon_concept.should_receive(:classifications_locked?).and_return(true)
      TaxonConceptReindexing.new(@taxon_concept).reindex
    }.should
      raise_error(EOL::Exceptions::ClassificationsLocked)
  end

  it 'should raise an error if too large' do
    lambda {
      @too_many_descendants = (0..@max_descendants).to_a
      TaxonConceptsFlattened.should_receive(:descendants_of).with(@taxon_concept.id).and_return(@too_many_descendants)
      TaxonConceptReindexing.new(@taxon_concept).reindex
    }.should
      raise_error(EOL::Exceptions::TooManyDescendantsToCurate)
  end

  it 'should NOT raise an error if too large but large trees are allowed' do
    @too_many_descendants = (0..@max_descendants).to_a
    CodeBridge.should_receive(:reindex_taxon_concept).and_return(nil)
    TaxonConceptReindexing.new(@taxon_concept, :allow_large_tree => true).reindex
  end

  it 'should call CodeBridge for the reindexing and lock classifications (also checking flatten option)' do
    CodeBridge.should_receive(:reindex_taxon_concept).with(@taxon_concept.id).and_return(nil)
    TaxonConceptReindexing.new(@taxon_concept).reindex
    @taxon_concept.reload
    @taxon_concept.classifications_locked?.should be_true
  end

end
