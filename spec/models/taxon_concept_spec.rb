require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonConcept do

  it 'should have different names for different detail levels' do
    concept = TaxonConcept.generate

    # trying to create a name ... seems to be *REALLY* hard to simply add a name to a TaxonConcept ...
    tc.taxon_concept_names.create :name => Name.gen, :language => Language.gen, :preferred => true, :vern => 0, :source_hierarchy_entry_id => HierarchyEntry.gen.id
    # ^ adds a valid TaxonConceptName but #name returns '?-?' (whatever that means) and #names returns [] ?
  end

end
