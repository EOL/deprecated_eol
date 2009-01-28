require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonConcept do

  it 'should add a TaxonConcept to the database when created' do
    lambda {
      Factory(:taxon_concept).should be_valid
    }.should change(TaxonConcept, :count).by(1)
  end

end
