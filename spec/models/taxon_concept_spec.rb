require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonConcept do

  it 'should ... be a TaxonConcept ...' do
    lambda {
      Factory(:taxon_concept).should be_valid
    }.should change(TaxonConcept, :count).by(1)
  end

end
